#########
# helper class for compatibilising Bioperl
# Bio::Search:::Result::ResultI objects with DrawableContainers

package EnsEMBL::Web::Container::HSPContainer;
use strict;

sub new {
  my $class = shift;
  my $object = shift;
  my $ticket = shift;
  my $results = shift;


  ( $ticket && $ticket->isa("EnsEMBL::ORM::Rose::Object::Ticket" ) ) or
    die( "Need a EnsEMBL::ORM::Rose::Object::Ticket object" );
  my $self = {object => $object, ticket => $ticket };
    
  my @hsps;
  foreach my $result (@$results){
    my $gzipped_serialsed_res = $result->{'result'};
    my $hit = $object->deserialise($gzipped_serialsed_res);
    $hit->{'id'} = $result->{'result_id'};
    push @hsps, $hit;
  }
 
  $self->{hsps} = [@hsps];

  return bless($self, $class);
}

sub start {
  my ($self) = @_;
  return 0;
}

sub end {
  my ($self) = @_;
  return $self->length;
}

sub length {
  my ($self) = @_;

  my $query_id = $self->name;  
  return  $self->{object}->retrieve_analysis_object->{'_seqs'}{$query_id}->length;
}

sub name {
  my ($self) = shift;
## This needs fixing!
  my @keys = keys %{$self->{object}->retrieve_analysis_object->{'_seqs'}};
  return $keys[0];
}

sub database{
  my ($self) = @_;
  return $self->{result}->database_name();
}

sub hits {
  my ($self) = @_;
  return $self->{result}->hits();
}

sub hsps{
  my ($self) = @_;
  return @{$self->{hsps}};
}

1;
