=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::TextSequence;

use strict;
use warnings;

use previous qw(buttons);

sub buttons {
  my $self    = shift;
  my $hub     = $self->hub;
  my $input   = $hub->input;
  my @buttons = $self->PREV::buttons(@_);

  if (my $blast_options = $self->blast_options) {
    my $button = {
      'caption'   => $blast_options->{'caption'} || 'BLAST this sequence',
      'url'       => $hub->url($blast_options->{'url'} || {qw(type Tools action Blast)}),
      'class'     => sprintf('blast hidden _blast_button%s', $blast_options->{'no_button'} ? ' _blast_no_button' : '')
    };

    $button->{'rel'} = $blast_options->{'seq_id'} || '' if $hub->species_defs->ENSEMBL_BLAST_BY_SEQID;

    push @buttons, $button;
  }

  return @buttons;
}

sub blast_options {
  ## Override this method to customise the 'BLAST this sequence' button
  ## @return Hashref with following keys (or undef to prevent displaying the button)
  ##  - caption: Button caption
  ##  - url: URL hashref as accepted by hub->url
  ##  - seq_id: Sequence id (JavaScript will parse the sequence displayed on the page if this is not provided) (only works is ENSEMBL_BLAST_BY_SEQID is on)
  ##  - no_button: Flag to disable the blast button, but keep the 'BLAST selected sequence' popup only
  return shift->hub->action =~ /Align|TranscriptComparison/ ? undef : {}; # disabled for Alignment pages by default
}

1;
