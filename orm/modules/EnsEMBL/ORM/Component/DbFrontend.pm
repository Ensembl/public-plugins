package EnsEMBL::ORM::Component::DbFrontend;

### NAME: EnsEMBL::ORM::Component::DbFrontend;
### Base class for components that make up the Ensembl CRUD interface 

### STATUS: Under Development

### DESCRIPTION:
### This module contains a lot of generic HTML/form generation code that
### is shared between similar pages (e.g. Add and Edit are essentially
### the same form, except that the latter loads a record from the db).

use strict;
use warnings;
no warnings 'uninitialized';

use EnsEMBL::Web::Form;
use EnsEMBL::Web::Data::User;

use base qw(EnsEMBL::Web::Component);

sub create_pagination {
### Creates a record navigation bar that allows the user to page 
### through n records at a time (requires the 'pagination' parameter 
### to be set to n in the interface configuration, where n is a 
### positive integer).
### Returns HTML
  my ($self, $pagination, $count) = @_;
  return unless ($pagination && $pagination > 0);
  $count ||= 0;
  my $hub = $self->model->hub;

  my ($prev_link, $next_link,$release);
  my $link_style = 'font-weight:bold;text-decoration:none';

  my $page = $hub->param('page') || 1; 
  $release = ";release=".$hub->param('release') if $hub->param('release');
  my $start = ($page - 1) * $pagination + 1;
  my $end = $page * $pagination; 
  if ($end >= $count) {
    $end = $count;
  }
  my $more = $count - $end;

  if ($page > 1) {
    my $prev_url = '/'.$hub->type.'/'.$hub->action.'?page='.($page-1).$release;
    $prev_link = qq(<a href="$prev_url" style="$link_style">&lt;&lt; Previous</a>);
  }
  if ($more) {
    my $next_url = '/'.$hub->type.'/'.$hub->action.'?page='.($page+1).$release;
    $next_link = qq(<a href="$next_url" style="$link_style">Next &gt;&gt;</a>);
  }

  my $html;
  if ($count) {
    $html .= qq(<table style="width:98%"><tr>
<td style="width:25%;text-align:left">$prev_link</td>
<td style="width:48%;text-align:center">Displaying records $start - $end of $count</td>
<td style="width:25%;text-align:right">$next_link</td>
</tr></table>);
  }
  else {
    $html .= qq(<p>No records</p>);
  }

  return $html;
}

sub create_form {
### Utility method for easy form creation
### Arguments: next (string) - action of this form
### Returns an EnsEMBL::Web::Form object
  my ($self, $next) = @_;
  my $hub = $self->hub;

  my $url = '/'.$hub->species_defs->species_path;
  $url = '' if $url !~ /_/;
  $url .= '/'.$hub->type.'/'.$next;

  my $form = EnsEMBL::Web::Form->new($hub->action, $url, 'post');
  $form->add_attribute('class', 'narrow-labels');
  return $form;
}

sub get_user_name {
### Utility method
### Argument: user ID (integer)
### Returns: user name (string)
  my ($self, $user_id) = @_;
  my $name = 'no-one';
        
  if ($user_id > 0) {
    my $user = EnsEMBL::Web::Data::User->new($user_id);
    $name = $user->name if $user;
  }
  return $name;
}

sub get_pretty_date {
### Utility method
### Argument: date (in MySQL format)
### Returns: date in user-friendly format (dd/mm/yy at hour::min)
  my ($self, $date) = @_;
  if ($date =~ /^0000-/) {
    return '';
  }
  else {
    return $self->pretty_date($date, 'simple_datetime');
  }
}

sub unpack_db_table {
### "Unpacks" the columns of a database into a hash of hashes
### that can be used to produce form elements. Default is to
### fully populate parameters with input form options
### Argument: mode (string, optional) - set to 'noedit' to return
###           all fields as type NoEdit and omit unnecessary steps
### Returns a hashref of key/hashref pairs, where each entry
### corresponds to the arguments of an EnsEMBL::Web::Form::Element
### object
  my ($self, $mode) = @_;
  my $param_set;
  my $data = $self->model->object;

  my @columns = @{$data->get_table_columns};
  push @columns, @{$data->get_m2m_columns};

  ## check for one-to-many foreign keys
  my %m2o_lookups = %{$data->get_m2o_lookups};

  foreach my $column (@columns) {
    my $name = $column->name;
    my $param = {'name' => $name};
    my $data_type = $column->type;

    ## set label
    my $label = ucfirst($name);
    $label =~ s/_/ /g;
    $param->{'label'} = $label;

    if ($mode eq 'noedit') {
      $param->{'type'} = 'NoEdit';
      if ($data_type eq 'enum' || $data_type eq 'set') {
        ## Set 'values' on lookups, so we can do reverse lookup later
        my $values  = $column->values;
        if (ref($values->[0]) eq 'HASH') {
          $param->{'values'} = $values;
        }
        else {
          my $tmp;
          foreach my $v (@$values) {
            push @$tmp, {'name' => $v, 'value' => $v};
          }
          $param->{'values'} = $tmp;
        }
        $param->{'values'} = $column->values;
      }
    }
    else {
      if ($column->is_primary_key_member || $name =~ /^created_|^modified_/) {
        $param->{'type'} = 'NoEdit';
        $param->{'is_primary_key'} = 1 if $column->is_primary_key_member;
      }
      elsif ($m2o_lookups{$name}) {
        $param->{'type'} = 'DropDown';
        $param->{'select'}  = 'select';
        $param->{'values'} = $m2o_lookups{$name};
      }
      elsif ($data_type eq 'enum' || $data_type eq 'set') {
        $param->{'select'}  = 'select';
        if ($data_type eq 'enum') {
          ## Use radio buttons if only two options
          my $values = $column->values;
          if (@$values < 3) {
            $param->{'select'} = 'radio';
          }
          $param->{'type'} = 'DropDown';
        }
        else {
          $param->{'type'} = 'MultiSelect';
        }
        my $values  = $column->values;
        if (ref($values->[0]) eq 'HASH') {
          $param->{'values'} = $values;
        }
        else {
          my $tmp;
          foreach my $v (@$values) {
            push @$tmp, {'name' => $v, 'value' => $v};
          }
          $param->{'values'} = $tmp;
        }
      }
      elsif ($name =~ /password/) {
        $param->{'type'} = 'Password';
      }
      elsif ($data_type eq 'integer') {
        $param->{'type'} = 'Int';
      }
      elsif ($data_type eq 'text') {
        $param->{'type'} = 'Text';
      }
      else {
        $param->{'type'} = 'String';
        if ($data_type eq 'varchar') {
          $param->{'maxlength'} = $column->length;
        }
      }
    }
    $param_set->{$name} = $param;
  }

  return $param_set;
}

1;
