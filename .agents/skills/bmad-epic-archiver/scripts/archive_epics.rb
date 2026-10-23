#!/usr/bin/env ruby
# frozen_string_literal: true

# BMAD Epic Archiver
# Archives fully-completed epics from sprint-status.yaml and epics.md
# to dedicated archive files, leaving lightweight stubs in the active files.
#
# Usage: ruby archive_epics.rb [project-root] [--dry-run]

TERMINAL_STATUSES = %w[done cancelled deferred].freeze
ARCHIVABLE_STORY_STATUSES = %w[done cancelled].freeze
ARCHIVE_NOTE_YAML = "# NOTE: Completed epics have been archived to sprint-status-archive.yaml"
ARCHIVE_NOTE_MD = "> **Note:** Completed epics have been archived to [epics-archive.md](epics-archive.md)."

class EpicArchiver
  def initialize(project_root, dry_run: false)
    @project_root = File.expand_path(project_root)
    @dry_run = dry_run
    @artifacts_dir = File.join(@project_root, "_bmad-output", "implementation-artifacts")
    @sprint_file = File.join(@artifacts_dir, "sprint-status.yaml")
    @sprint_archive = File.join(@artifacts_dir, "sprint-status-archive.yaml")
    @epics_file = File.join(@artifacts_dir, "epics.md")
    @epics_archive = File.join(@artifacts_dir, "epics-archive.md")
  end

  def call
    unless File.exist?(@sprint_file)
      warn "ERROR: #{@sprint_file} not found"
      exit 1
    end

    blocks = parse_sprint_blocks
    archivable = blocks.select { |b| archivable?(b) }
    archived_story_keys = load_archived_story_keys(@sprint_archive)
    archivable.each { |b| partition_stories!(b, archived_story_keys) }
    archivable.select! { |b| b[:stories_to_archive].any? || !archived_in_active_file?(b) }

    if archivable.empty?
      puts "No new archivable epics found."
      return
    end

    epic_list = archivable.sort_by { |b| b[:epic_num] }.map { |b| b[:epic_num] }.join(", ")
    puts "Found #{archivable.size} archivable epic(s): #{epic_list}"
    puts

    archive_sprint_status(archivable)

    # Only full epics (no deferred stories retained) are eligible for epics.md section archival.
    md_archivable = archivable.select { |b| b[:stories_to_keep].empty? && b[:stories_to_archive].any? }
    archive_epics_md(md_archivable) if File.exist?(@epics_file) && md_archivable.any?

    puts @dry_run ? "\n[DRY RUN] No files were modified." : "\nDone! Archives created/updated."
  end

  private

  # --- Sprint-status.yaml parsing ---

  def parse_sprint_blocks
    lines = File.readlines(@sprint_file, chomp: true)
    dev_start = lines.index { |l| l.strip == "development_status:" }
    return [] unless dev_start

    raw_blocks = split_into_blocks(lines, dev_start + 1)
    raw_blocks.filter_map { |entries| build_block(entries) }
  end

  def split_into_blocks(lines, start_index)
    blocks = []
    current = []

    (start_index...lines.size).each do |i|
      if lines[i].strip.empty?
        blocks << current unless current.empty?
        current = []
      else
        current << { index: i, text: lines[i] }
      end
    end
    blocks << current unless current.empty?
    blocks
  end

  def build_block(entries)
    epic_num = nil
    title_line = nil

    entries.each do |entry|
      if entry[:text] =~ /#\s*Epic\s+(\d+):/
        epic_num = Regexp.last_match(1).to_i
        title_line = entry[:text]
      end
    end
    return nil unless epic_num

    stories = {}
    story_entries = []
    epic_key = nil
    epic_line = nil
    retro_line = nil

    entries.each do |entry|
      next unless entry[:text] =~ /^\s+([\w.-]+):\s*(\S+)/

      key = Regexp.last_match(1)
      status = Regexp.last_match(2)

      if key =~ /\Aepic-(\d+)/
        next unless Regexp.last_match(1).to_i == epic_num

        if key.end_with?("-retrospective")
          retro_line = entry[:text]
        else
          epic_key = key
          epic_line = entry[:text]
        end
      elsif key =~ /\A(\d+)-/ && Regexp.last_match(1).to_i == epic_num
        stories[key] = status
        story_entries << {
          key: key,
          status: status,
          text: entry[:text],
          index: entry[:index]
        }
      end
    end

    {
      epic_num: epic_num,
      entries: entries,
      line_indices: entries.map { |e| e[:index] },
      lines: entries.map { |e| e[:text] },
      stories: stories,
      story_entries: story_entries,
      epic_key: epic_key,
      epic_line: epic_line,
      title_line: title_line,
      retro_line: retro_line
    }
  end

  def archivable?(block)
    return false if block[:stories].empty?

    block[:stories].values.all? { |s| TERMINAL_STATUSES.include?(s) }
  end

  def archived_in_active_file?(block)
    block[:title_line].to_s.include?("(archived)")
  end

  def partition_stories!(block, archived_story_keys)
    block[:stories_to_archive] = block[:story_entries].select do |entry|
      ARCHIVABLE_STORY_STATUSES.include?(entry[:status]) && !archived_story_keys.include?(entry[:key])
    end
    block[:stories_to_keep] = block[:story_entries].select { |entry| entry[:status] == "deferred" }
  end

  # Epic 0 is perpetual — archive stories but keep epic stub
  def perpetual_epic?(block)
    block[:epic_num].zero?
  end

  def load_archived_story_keys(archive_file)
    return Set.new unless File.exist?(archive_file)

    content = File.read(archive_file)
    keys = Set.new
    content.scan(/^\s+((?:\d+)-[\w.-]+):\s*\S+/) { |m| keys << m[0] }
    keys
  end

  def load_archived_epic_nums(archive_file)
    return Set.new unless File.exist?(archive_file)

    content = File.read(archive_file)
    nums = Set.new
    content.scan(/#+\s*Epic\s+(\d+):/) { |m| nums << m[0].to_i }
    nums
  end

  # --- Sprint-status.yaml archiving ---

  def archive_sprint_status(archivable)
    lines = File.readlines(@sprint_file, chomp: true)
    archive_parts = []

    archivable.sort_by { |b| -b[:line_indices].first }.each do |block|
      moved_count = block[:stories_to_archive].size
      kept_count = block[:stories_to_keep].size
      puts "  sprint-status: Epic #{block[:epic_num]} (move #{moved_count}, keep #{kept_count} deferred) -> archive"
      archive_block = build_sprint_archive_block(block)
      archive_parts.unshift(archive_block) if archive_block

      next if @dry_run

      updated_lines = build_updated_sprint_block(block)
      lines[block[:line_indices].first..block[:line_indices].last] = updated_lines
    end

    return if @dry_run

    add_archive_note_yaml(lines)
    File.write(@sprint_file, lines.join("\n") + "\n")
    write_sprint_archive(archive_parts) if archive_parts.any?
  end

  def build_updated_sprint_block(block)
    stories_to_keep = block[:stories_to_keep]
    keep_keys = stories_to_keep.map { |s| s[:key] }.to_set
    stories_to_keep_by_index = stories_to_keep.to_h { |s| [s[:index], s[:text]] }
    all_story_indexes = block[:story_entries].map { |s| s[:index] }.to_set

    title = block[:title_line].sub(/#\s*Epic\s+\d+:\s*/, "").strip
    title = title.sub(/\s*\(archived\)\s*$/, "")
    indent = block[:title_line][/^\s*/]

    block[:entries].each_with_object([]) do |entry, output|
      text = entry[:text]
      index = entry[:index]

      if index == title_line_index(block)
        output << "#{indent}# Epic #{block[:epic_num]}: #{title} (archived)"
      elsif block[:epic_key] && text =~ /^\s*#{Regexp.escape(block[:epic_key])}:\s*\S+/
        output << "#{indent}#{block[:epic_key]}: done  # Stories archived -> sprint-status-archive.yaml"
      elsif all_story_indexes.include?(index)
        output << stories_to_keep_by_index[index] if keep_keys.include?(story_key_for_line(text))
      else
        output << text
      end
    end
  end

  def title_line_index(block)
    block[:entries].find { |entry| entry[:text] == block[:title_line] }&.dig(:index)
  end

  def story_key_for_line(text)
    return nil unless text =~ /^\s+([\w.-]+):\s*\S+/

    Regexp.last_match(1)
  end

  def build_sprint_archive_block(block)
    return nil if block[:stories_to_archive].empty?

    title = block[:title_line].sub(/#\s*Epic\s+\d+:\s*/, "").strip
    title = title.sub(/\s*\(archived\)\s*$/, "")
    indent = block[:title_line][/^\s*/]

    archive_lines = []
    archive_lines << "#{indent}# Epic #{block[:epic_num]}: #{title}"
    archive_lines << "#{indent}#{block[:epic_key]}: done" if block[:epic_key]
    block[:stories_to_archive].each { |entry| archive_lines << entry[:text] }
    archive_lines << block[:retro_line] if block[:retro_line]
    archive_lines.join("\n")
  end

  def add_archive_note_yaml(lines)
    return if lines.any? { |l| l.strip == ARCHIVE_NOTE_YAML }

    insert_at = lines.index { |l| l =~ /\A\w/ && l !~ /\A#/ } || 0
    lines.insert(insert_at, ARCHIVE_NOTE_YAML, "")
  end

  def write_sprint_archive(parts)
    if File.exist?(@sprint_archive)
      File.open(@sprint_archive, "a") do |f|
        parts.each do |p|
          f.puts
          f.puts p
        end
      end
    else
      File.open(@sprint_archive, "w") do |f|
        f.puts "# Sprint Status Archive"
        f.puts "# Completed epics archived from sprint-status.yaml"
        f.puts
        f.puts "archived_development_status:"
        parts.each do |p|
          f.puts
          f.puts p
        end
      end
    end
  end

  # --- Epics.md archiving ---

  def archive_epics_md(archivable)
    lines = File.readlines(@epics_file, chomp: true)
    archivable_nums = Set.new(archivable.map { |b| b[:epic_num] })
    already_archived_md = load_archived_epic_nums(@epics_archive)

    sections = parse_epic_md_sections(lines)
    to_archive = sections.select do |s|
      archivable_nums.include?(s[:epic_num]) && !already_archived_md.include?(s[:epic_num])
    end
    return if to_archive.empty?

    archive_parts = []

    to_archive.sort_by { |s| -s[:start_line] }.each do |section|
      line_count = section[:end_line] - section[:start_line] + 1
      puts "  epics.md: Epic #{section[:epic_num]} (#{line_count} lines) -> archive"
      archive_parts.unshift(lines[section[:start_line]..section[:end_line]].join("\n"))

      next if @dry_run

      stub_lines = build_epic_md_stub(section, lines).split("\n")
      lines[section[:start_line]..section[:end_line]] = stub_lines
    end

    return if @dry_run

    add_archive_note_md(lines)
    File.write(@epics_file, lines.join("\n") + "\n")
    write_epics_archive(archive_parts)
  end

  def parse_epic_md_sections(lines)
    sections = []
    current = nil

    lines.each_with_index do |line, i|
      if line =~ /^## Epic (\d+):\s*(.+)/
        if current
          current[:end_line] = trim_section_end(lines, current[:start_line], i)
          sections << current
        end
        current = { epic_num: Regexp.last_match(1).to_i, title: Regexp.last_match(2).strip, start_line: i }
      elsif current && line =~ /^## / && line !~ /^## Epic \d+:/
        current[:end_line] = trim_section_end(lines, current[:start_line], i)
        sections << current
        current = nil
      end
    end

    if current
      current[:end_line] = trim_section_end(lines, current[:start_line], lines.size)
      sections << current
    end

    sections
  end

  def trim_section_end(lines, start, next_start)
    end_line = next_start - 1
    end_line -= 1 while end_line > start && lines[end_line].strip.empty?
    end_line
  end

  def build_epic_md_stub(section, lines)
    header = lines[section[:start_line]]
    [
      header,
      "",
      "**Status:** Done -- Archived. See [epics-archive.md](epics-archive.md) for full story details.",
      "",
      "---"
    ].join("\n")
  end

  def add_archive_note_md(lines)
    return if lines.any? { |l| l.strip == ARCHIVE_NOTE_MD }

    in_frontmatter = false
    insert_at = 0
    lines.each_with_index do |line, i|
      if line.strip == "---"
        if in_frontmatter
          insert_at = i + 1
          break
        else
          in_frontmatter = true
        end
      end
    end

    lines.insert(insert_at, "", ARCHIVE_NOTE_MD, "")
  end

  def write_epics_archive(parts)
    if File.exist?(@epics_archive)
      File.open(@epics_archive, "a") do |f|
        parts.each do |p|
          f.puts
          f.puts p
        end
      end
    else
      File.open(@epics_archive, "w") do |f|
        f.puts "# Archived Epics"
        f.puts
        f.puts "Completed epics archived from [epics.md](epics.md)."
        f.puts
        f.puts "---"
        parts.each do |p|
          f.puts
          f.puts p
        end
      end
    end
  end
end

require "set"

project_root = ARGV.find { |a| !a.start_with?("--") } || Dir.pwd
dry_run = ARGV.include?("--dry-run")

EpicArchiver.new(project_root, dry_run: dry_run).call
