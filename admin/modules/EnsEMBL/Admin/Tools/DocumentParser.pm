package EnsEMBL::Admin::Tools::DocumentParser;

### Rules for file formatting
### Three hashes, ### in the begining of a line create a new section
### Two hashes, ## in the begining of a line create a new heading. Number of stats, * after # tells the level of heading
### Anything else starting with # is ignored
### Bullets and numbering:
### Lines with *, - or ~ in the begining, just after the indent are considered as list statements
### Indents can be increased and decreased by a differnce of 2 to actually increase the indent in the output document
### If total indent is odd, it's considered as code
### Anything with [html] in the front is not parsed and saved as html

use strict;
use warnings;

use EnsEMBL::Web::DOM;
use EnsEMBL::Web::Exceptions;

use Exporter qw(import);
our @EXPORT     = qw(parse_file file_to_htmlnodes);
our %LIST_STYLE = qw(number \* bullet \- alphabet \~);

sub parse_file {
  ## Parses a file to a data structure
  ## @param File location string
  ## @return ArrayRef of parsed file
  my $file_location = shift;

  my $section_name  = '__';
  my $pointer       = new_block(undef, {'category' => 'section'});
  my @parsed_file   = ($section_name => $pointer);
  my $line_number   = 0;
  my $list_types    = {%LIST_STYLE};

  open FILE, "<", $file_location;

  ## TODO - throw exception('FileNotFound') if file missing

  while (my $line = <FILE>) {
    chomp $line;
    $line_number++;

    ## For raw html
    if ($line =~ s/^\s*\[html\]//) {
      $pointer = new_block($pointer, {'category' => 'html'}) unless ($pointer->{'category'} eq 'html');
      append_html($pointer, $line);
      next;
    }

    ## Remove html block for anything else
    $pointer = $pointer->{'parent'} if $pointer->{'category'} eq 'html';    

    ## For anything starting with hash (#)
    if ($line =~ /^#/) {
    
      ## For a new section - triple hash (###)
      if ($line =~ /^[#]{3}\s*([a-z]+)\s*$/i) {
        $pointer = new_block(undef, {'category' => 'section'});
        push @parsed_file, (($section_name = $1) => $pointer);

      ## For a new heading - double hash (##)
      } elsif ($line =~ /^[#]{2}\s*([^#]{1}.*)\s*$/) {

        if ($section_name ne '__content') {
          $section_name   = '__content';
          $pointer = new_block(undef, {'category' => 'section'});
          push @parsed_file, ($section_name => $pointer);
        }

        $1 =~ /^(\**)\s*(.*)$/;
        my $label = $2;
        my $level = length $1;

        $pointer = $pointer->{'parent'} while (!($pointer->{'category'} eq 'section' || $pointer->{'category'} eq 'heading' && $pointer->{'level'} < $level));
        $pointer = new_block($pointer, {'category' => 'heading', 'label' => $label, 'level' => $level});
      }
      next; # ignore single hash (#)
    }

    ## empty lines
    if ($line =~ /^\s*$/) {

      if ($pointer->{'category'} eq 'code') {
        append_code($pointer, '');
      }
      elsif ($pointer->{'category'} !~ /^(section|heading)$/) {
        append_text($pointer, '', 1);
      }
      next;
    }

    ## Anything other than line starting with # or an empty line or html

    # Find the indent
    $line =~ s/^(\s*)//;
    my $indent = length $1;

    # If indent is odd, its for code text
    if ($indent % 2) {
      $pointer = new_block($pointer, {'category' => 'code', 'indent' => $indent}) unless $pointer->{'category'} eq 'code';
      append_code($pointer, (' ' x ($indent - $pointer->{'indent'})) . $line);
      next;
    }

    # Close code block if any
    $pointer = $pointer->{'parent'} if $pointer->{'category'} eq 'code';

    # If list text
    my $list_type;
    my $list_sign;
    $list_type = $list_types->{$_} and $line =~ s/^($list_type\s+)// and $list_sign = $1 and last or $list_type = '' for keys %$list_types;
    if ($list_type) {

      # if it's not continued from existing list
      unless ($pointer->{'category'} eq 'list' && $list_type eq $list_types->{$pointer->{'list_type'}} && $pointer->{'indent'} == $indent) {

        # Get the appropriate parent pointer considering the current indent
        $pointer = $pointer->{'parent'} while ($pointer->{'indent'} || -1) >= $indent;

        # Create new list block
        $pointer = new_block($pointer, {
          'category'        => 'list',
          'indent'          => $indent,
          'list_type'       => {reverse %$list_types}->{$list_type},
          'wrapped_indent'  => $indent + length $list_sign
        });
      }

      append_text($pointer, $line, 1);
      next;
    }

    # If list text wrapped to next line
    if ($pointer->{'category'} eq 'list' && $pointer->{'wrapped_indent'} == $indent) {
      append_text($pointer, $line);
      next;
    }

    # Close any open list block
    $pointer = $pointer->{'parent'} if $pointer->{'category'} eq 'list';

    # Create a new paragraph if existing one is heading
    $pointer = new_block($pointer, {'category' => 'paragraph', 'indent' => $indent}) if $pointer->{'category'} =~ /^(heading|section)$/;

    # Create new paragraph block if indent changed
    if ($pointer->{'indent'} != $indent) {
      $pointer = $pointer->{'parent'} while ($pointer->{'indent'} || -1) >= $indent;
      $pointer = new_block($pointer, {'category' => 'paragraph', 'indent' => $indent});
    }

    # Add text to the existing paragraph
    append_text($pointer, $line);
  }
  close FILE;

  build_toc(\@parsed_file);

  return \@parsed_file;
}

sub file_to_htmlnodes {
  ## Converts the parsed file to a tree of dom nodes
  ## @param Parsed file - output from EnsEMBL::Web::Tools::DocumentParser::parse_file
  ## @param DOM object (create a new one if missed)
  my $file    = shift;
  my $dom     = shift || new EnsEMBL::Web::DOM;
  my $content = $dom->create_element('div');
  my $toc_div = $dom->create_element('div', {'class' => 'document_toc', 'flags' => {'section', '_toc'}});

  while (my ($section_name, $section) = splice @$file, 0, 2) {
    if ($section_name eq '_toc') {
      $toc_div->append_children($dom->create_element('h2', {'class' => 'document_h', 'inner_text' => 'Table of contents'}), map toc_to_htmlnode($_, $dom, $dom->create_element('div')), @$section);
    } else {
      $content->append_child('div', {
        'flags'     => {'section' => $section_name},
        'children'  => [ map {textsection_to_htmlnode($_, $dom)} @{$section->{'children'}} ]
      });
    }
  }

  if (my $content_section = shift @{$content->get_nodes_by_flag({'section' => '__content'}) || []}) {
    $content_section->before($toc_div);
  }
  return $content;
}

## HELPER FUNCTIONS - not imported

sub new_block {
  ### Block type
  # KEYS      'category' 'children' 'indent' 'label' 'level' 'wrapped_indent' 'list_type' 'wrapper' 'html'
  # section:     yes        yes       no       no      no         no              no         no       no
  # heading:     yes        yes       no       yes     yes        no              no         no       no
  # code:        yes        yes       yes      no      no         no              no         no       no
  # paragraph:   yes        yes       yes      no      no         no              no         no       no
  # list:        yes        yes       yes      no      no         yes             yes        no       no
  # html:        yes        no        no       no      no         no              no         no       yes
  my ($parent, $pointer) = @_;
  if ($parent) {
    $pointer->{'parent'} = $parent;
    push @{$parent->{'children'}}, $pointer;
  }
  $pointer->{'children'} = [];
  return $pointer;
}

sub append_text {
  my ($pointer, $text, $next_line) = @_;
  push @{$pointer->{'children'}}, '' if $next_line || !scalar @{$pointer->{'children'}} || ref $pointer->{'children'}[-1];
  $pointer->{'children'}[-1] .= $pointer->{'children'}[-1] eq '' ? "$text" : " $text";
}

sub append_code {
  my ($pointer, $code) = @_;
  push @{$pointer->{'children'}}, "$code";
}

sub append_html {
  my ($pointer, $html) = @_;
  $pointer->{'html'}  = '' unless exists $pointer->{'html'};
  $pointer->{'html'} .= $html;
}

sub textsection_to_htmlnode {
  my ($text_section, $dom) = @_;

  if (ref $text_section) {
    my $return_div = $dom->create_element('div');

    if ($text_section->{'category'} eq 'section') {
      $return_div->append_children(map {textsection_to_htmlnode($_, $dom)} @{$text_section->{'children'}});

    } elsif ($text_section->{'category'} eq 'heading') {
    
      my $url_hash = to_url_hash($text_section->{'level'}, $text_section->{'label'});

      $return_div->append_children(
        $dom->create_element(sprintf('h%d', $text_section->{'level'} + 1), {
          'class'       => 'document_h',
          'id'          => $url_hash,
          'inner_HTML'  => sprintf('%s %s <a href="#%s">&para;</a>', $text_section->{'number'}, $return_div->encode_htmlentities($text_section->{'label'}), $url_hash)
        }),
        map {textsection_to_htmlnode($_, $dom)} @{$text_section->{'children'}}
      );

    } elsif ($text_section->{'category'} eq 'list') {
      $return_div->set_attribute('class', "list_$text_section->{'list_type'}");
      $return_div->append_children(map {
        $_ ? $dom->create_element('div', {'class' => "list_element", 'children' => [ textsection_to_htmlnode($_, $dom) ]} ) : ()
      } @{$text_section->{'children'}});

    } elsif ($text_section->{'category'} eq 'code') {
      $return_div->set_attribute('class', 'code');
      $return_div->append_children(map {
        ($_ = $return_div->encode_htmlentities($_)) =~ s/\s/&nbsp;/g;
        $dom->create_element('p', {'class' => 'document_p', 'inner_HTML' => $_})
      } @{$text_section->{'children'}});

    } elsif ($text_section->{'category'} eq 'html') {
      $return_div->append_child('div', {'class' => 'document_div', 'inner_HTML' => $text_section->{'html'}});

    } elsif ($text_section->{'category'} eq 'paragraph') {
      $return_div->append_children(map {textsection_to_htmlnode($_, $dom)} @{$text_section->{'children'}});
    }
    return $return_div;
  }
  else {
    my $p = $dom->create_element('p', {'class' => 'document_p'});
    inner_HTML($p, $text_section);
    return $p;
  }
}

sub toc_to_htmlnode {
  my ($heading, $dom, $parent) = @_;
  my $div = $parent->append_child('div', {'children' => [
    $dom->create_element('p', {'inner_HTML' => sprintf('%s&nbsp;<a href="#%s">%s</a>', $heading->{'number'}, to_url_hash($heading->{'level'}, $heading->{'label'}), $heading->{'label'})})
  ] });
  toc_to_htmlnode($_, $dom, $div) for @{$heading->{'children'}};
  return $parent;
}

sub to_url_hash {
  my ($level, $label) = @_;
  $label =~ s/[^a-z0-9\-\_]+/_/gi;
  return sprintf('%s%s', '_' x $level, $label);
}

sub build_toc {
  my $file = shift;
  my $i    = 0;
  $i++ while $i < @$file && (ref ($file->[$i] || '') || ($file->[$i] || '') ne '__content');
  push @$file, '_toc', _build_toc($file->[++$i]{'children'}) if $i < @$file;
}

sub _build_toc {
  my $blocks = shift;
  my $number = 0;

  return [ map {
    if ($_->{'category'} eq 'heading') {
      $_->{'number'} = $_->{'parent'}{'number'} ? sprintf('%s.%s', $_->{'parent'}{'number'}, ++$number) : ++$number;
    }
    $_->{'category'} ne 'heading' ? () : {
      'number'    => $_->{'number'},
      'level'     => $_->{'level'},
      'label'     => $_->{'label'},
      'children'  => _build_toc($_->{'children'})
    }
  } @$blocks ];
}

sub inner_HTML {
  my ($node, $text) = @_;
  my $email_qr  = qr/\[email(\s*\=\s*([^\]]+))?\]([^\[]+)\[\/email\]/;
  my $url_qr    = qr/\[url(\s*\=\s*([^\]]+))?\]([^\[]+)\[\/url\]/;
  while ($text =~ /$email_qr/g) {
    my $email = $2 || $3;
    my $html  = $3;
    $text     =~ s/$email_qr/\[a=mailto:$email\]$html\[\/a\]/;
  }
  while ($text =~ /$url_qr/g) {
    my $url   = $2 || $3;
    my $html  = $3;
    $url      = "http://$url" unless $url =~ /^(ht|f)tp(s?):\/\//;
    $text     =~ s/$url_qr/\[a=$url\]$html\[\/a\]/;
  }

  $text = $node->encode_htmlentities($text);
  $text =~ s/\[a\s*\=\s*([^\]\s]+)]/<a href="$1">/g;
  $text =~ s/\[(\/?(a|b|i))\]/<$1>/g;
  $text =~ s/\[\s*code\s*\]/<span class="code">/g;
  $text =~ s/\[\s*\/\s*code\s*\]/<\/span>/g;
  $node->inner_HTML($text);
}

1;