=head1 LICENSE

Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Component::Tools::Download;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(EnsEMBL::Web::Component::Tools);
use Bio::Root::IO; 
use Bio::EnsEMBL::Utils::IO qw/iterate_file/;

sub _init { 
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub content { 
  my $self = shift; 
  if ($self->hub->param('format') eq 'raw') {
    $self->print_raw_format;
  }
}


sub print_raw_format {
  my $self = shift;
  my $object = $self->object;  
  my $name = $self->hub->param('tk');
  my $filename = $self->hub->param('file');

  

  my $filepath = sprintf (  '%s/%s/%s/%s',
    $object->species_defs->ENSEMBL_TMP_DIR_BLAST,
    substr($name, 0, 6),
    substr($name, 6),
    $filename
  );


  iterate_file($filepath, sub {
    my ($line) = @_;
    print $line;
  });
}

1;
