package EnsEMBL::Web::Component::Website::CurrentSpecies;

### Lists species recorded in the ensembl_website database, 
### as opposed to those configured in SiteDefs

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component);
use EnsEMBL::Web::Data::Release;
use EnsEMBL::Web::Data::ReleaseSpecies;

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
}

sub caption {
  my $self = shift;
  return '';
}

sub content {
  my $self = shift;
  my $object = $self->object;
  my $html;
  my $links = qq(<p><a href="/Website/AddSpecies">Add a new species</a> | <a href="/Website/UpdateSpecies">Update database with current species</a></p>);

  my $release_id = $object->species_defs->ENSEMBL_VERSION;
  my $release = EnsEMBL::Web::Data::Release->new($release_id);

  my @config_species = $object->species_defs->valid_species;
  my %species_lookup;
  foreach my $species (@config_species) {
    $species_lookup{$species} = 'yes';
  }
  
  if ($release) {
    $html = qq(<h1>Species currently in ensembl_website for Release $release_id</h1>
<div class="info-box" style="width:50%;margin:10px auto;padding:1em">
N.B. You will normally only need to update the list of current species if it is empty 
(e.g. at the beginning of the release cycle).
</div>
    );
 
    my $rs = EnsEMBL::Web::Data::ReleaseSpecies->new(); 
    my @xids = $rs->search({'release_id' => $release_id});
    warn "XIDS @xids";
    my @species;
    foreach my $xid (@xids) {
      push @species, EnsEMBL::Web::Data::Species->new($xid->species_id);
    }
    if (@species) {
      $html .= $links;
      $html .= "<ul>\n";
      foreach my $species (sort {$a->name cmp $b->name} @species) {
        $html .= '<li>'.$species->name;
        $html .= ' - NEW! (add ini file when db is available)' unless $species_lookup{$species->name};
        $html .= "</li>\n";
      }
      $html .= "</ul>\n";
    }
    else {
      $html .= $self->_warning('Action required', qq(No species for the current release have yet been added to the ensembl_website database!));
    }
    $html .= $links;
  }
  else {
    $html .= $self->_warning('Action required', qq(Release $release_id has not been added to the ensembl_website database!));

    my $form = EnsEMBL::Web::Form->new('add_release', '/Website/UpdateRelease', 'post');

    $form->add_element(
      'name' => 'date',
      'type' => 'String',
      'label' => 'Scheduled release date (YYYY-MM-DD)',
      'required' => 'yes',
    );
    $form->add_element(
      'name' => 'submit',
      'type' => 'Submit',
      'value' => 'Save',
    );

    $html .= $form->render;
  }
  return $html;
}

1;
