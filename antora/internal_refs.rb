# https://docs.asciidoctor.org/asciidoc/latest/sections/auto-ids/
# Convert internal links use correct xref format for autogenerated IDs

# all, link, angled, hyphen
fix_type =  ARGV[0].downcase

# convert link macro to xref macro to enable validation
if fix_type == "all" || fix_type == "link"
  puts "Converting link macros to xref macro"

  files_with_link = %x[ grep -rlE --include \\*.adoc "link:\.{1,2}/[^\[]*" ]

  files_with_link.split.uniq.each do |file|
    internal_links_in_file = %x[ grep -oE "link:\.{1,2}/[^\[]*" #{file} ]
    internal_links_in_file.split.uniq.each do |link|
      new_link = link.sub("link:./","xref:./").sub("link:../","xref:../")
      %x[ sed -i "s|#{link}|#{new_link}|g" #{file} ]
    end
  end
  puts "Done"
end

# Angled brackets
# E.g. <<some-section-header, Some Section Header>> becomes <<_some_secton_header, Some Section Header>>
if fix_type == "all" || fix_type == "angled"
  puts "Fixing formatting of internal xrefs using angled brackets"

  files_with_link = %x[ grep -rlE --include \\*.adoc "<<.*>>" ]

  files_with_link.split.uniq.each do |file|
    internal_links_in_file = %x[ grep -oE "<<(.*)>>" #{file} ].chomp
    internal_links_in_file.split("\n").uniq.each do |link|
      new_link = ""
      if link.include?(",")
        new_link = link.split(",")[0].downcase.gsub("-","_").gsub(" ","_").gsub(/_+/,"_")
        if !new_link.start_with?("<<_")
          new_link.sub!("<<","<<_")
        end
        sanitized_label = #{link.split(',')[1]}.gsub("/","\\/")
        %x[ sed -i "s|#{link.split(',')[0]},#{sanitized_label}|#{new_link},#{sanitized_label}|g" #{file} ]
      else
        new_link = link.downcase.gsub("-","_").gsub(" ","_").gsub(/_+/,"_")
        if !new_link.start_with?("<<_")
          new_link = new_link.sub("<<","<<_")
        end
        %x[ sed -i "s|#{link}|#{new_link}|g" #{file} ]     
      end
    end
  end
  puts "Done"
end

# xref macro but section ID (fragment/hash) contains hyphens or missing initial underscore
# E.g. xref:page.adoc#header becomes xref:page.adoc#_header
# E.g. xref:page.adoc#_some-section-header becomes xref:page.adoc#_some_section_header
if fix_type == "all" || fix_type == "hyphen"
  puts "Convert hyphen to underscore for xref macros"

  files_with_link = %x[ grep -rlE --include \\*.adoc "xref:[^\[]*" ].chomp

  files_with_link.split.uniq.each do |file|
    internal_links_in_file = %x[ grep -oE "xref:[^\[]*" #{file} ].chomp
    internal_links_in_file.split.uniq.each do |link|
      if !link.include?("#")
        next
      end

      header = link[/#.*/]
      new_header = header.gsub("-","_")
      
      if !new_header.start_with?("#_")
        new_header.sub!("#","#_")
      end

      new_link = link.sub(header, new_header)
      new_link.gsub!(/_+/,"_")
      
      %x[ sed -i "s|#{link}|#{new_link}|g" #{file} ]
    end
  end
  puts "Done"
end