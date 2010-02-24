package EnsEMBL::Web::Document::HTML::TwoColTable;

use strict;
use CGI qw(escapeHTML);

sub new {
  my $class = shift;
  my $self = { 'content' => [] };
  bless $self, $class;
  return $self;
}

sub _row {
  my($self, $label, $value ) = @_;
  return sprintf '<tr>
    <th>%s</th>
    <td>%s</td>
  </tr>', escapeHTML($label), $value;
}

sub add_row {
  my($self, $label, $value) = @_;
  push @{$self->{'content'}}, $self->_row( $label, $value );
}

sub render {
  my $self = shift;
  my $html = qq(<table class="twocol">\n);
  $html .= join '',@{$self->{'content'}};
  $html .= "</table>\n";
  return $html;
}

1;
