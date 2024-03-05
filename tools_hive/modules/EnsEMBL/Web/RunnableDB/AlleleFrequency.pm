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

package EnsEMBL::Web::RunnableDB::AlleleFrequency;

### Hive Process RunnableDB for Allele frequency tool

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::SystemCommand;
use EnsEMBL::Web::Utils::FileHandler qw(file_get_contents);
use EnsEMBL::Web::Utils::FileSystem qw(list_dir_contents);
use EnsEMBL::Web::File::Utils::URL;

use parent qw(EnsEMBL::Web::RunnableDB);

sub fetch_input {
  ## @override
  my $self = shift;

  my $output_file  = $self->param_required('output_file');
  my $work_dir     = $self->param_required('work_dir');
  my $input_file   = $self->param_required('input_file');
  my $sample_panel = $self->param_required('sample_panel');
  my $population   = $self->param_required('population');
  my $region       = $self->param_required('region');  
  my $proxy        = $self->param_required('proxy');
  my $code_root    = $self->param_required('code_root');
  my $tabix        = $self->param_required('tabix');
  my $bgzip        = $self->param_required('bgzip');
  my $trim_file;

  #splitting big vcf file based on region using tabix
  $input_file    =~ m!([^/]+)$!;
  (my $shortname  = $1) =~ s/\.gz//g;
  
  # splitting the file based on the region using tabix
  my $index_resp = EnsEMBL::Web::SystemCommand->new($self, "cd $work_dir;$tabix -f -h -p vcf $input_file $region > $shortname;")->execute();
  if ($index_resp->error_code) {
    my $exitcode = $? >>8;
    throw exception("Tabix error","Allele Frequency Calculation ERROR, TABIX: $exitcode") if $exitcode;
  }

  #gzipping the splitted files and deleting uncompress file to free up space after gzipping
  my $gzip_cmd = EnsEMBL::Web::SystemCommand->new($self, "$bgzip -c $work_dir/$shortname > $work_dir/$shortname.gz; rm $work_dir/$shortname")->execute();
  if(!$gzip_cmd->error_code) {
    $trim_file  = $work_dir."/".$shortname.".gz";
    throw exception('HiveException', "Gzipping error: ".$gzip_cmd->error_code) unless -s $trim_file;
  }
  
  #creating new index file based on splitted file but before removing original index file
  my $index_file_cmd = EnsEMBL::Web::SystemCommand->new($self, "rm $work_dir/$shortname.gz.tbi;cd $work_dir;$tabix -f -p vcf $shortname.gz")->execute();
  if($index_file_cmd->error_code) {
    throw exception('HiveException', "Index file error: ".$index_resp->error_code) unless -s $shortname.".gz.tbi";
  }

  $self->param('__input_file', $input_file);
  $self->param('__trim_file', $trim_file);
  $self->param('__region', $region);
  $self->param('__population', $population);
  $self->param('__sample_panel', $sample_panel);
  $self->param('__tabix', $tabix);
  $self->param('__output_file', sprintf('%s/%s', $work_dir, $output_file));
  $self->param('__log_file', sprintf('%s/%s.log', $work_dir, $output_file ));  
}

sub run {
  my $self      = shift;
  my $log_file  = $self->param('__log_file');

  my $command = EnsEMBL::Web::SystemCommand->new($self, sprintf('perl %s ', $self->param('AF_bin_path')), {
    '-vcf'          => $self->param('__trim_file'),
    '-sample_panel' => $self->param('__sample_panel'),
    '-region'       => $self->param('__region'),
    '-pop'          => $self->param('__population'),
    '-tabix'        => $self->param('__tabix'),
    '-out_file'     => $self->param('__output_file')
  })->execute({
    'log_file'    => $log_file,
  });

  # throw exception if process failed
  if (my $error_code = $command->error_code) {
    my $error_details = join('', grep(/MSG/, file_get_contents($log_file)));

    #PRECAUTIONARY MEASURE: do cleanup in case job failed for some other reason
    my @del_files   = ($self->param('__log_file'), $self->param('__trim_file'), $self->param('__trim_file').".tbi", $self->param('__sample_panel'));
    for my $file (@del_files) {
      unlink $file if (-f $file);
    }

    ($error_details) = file_get_contents($log_file) if(!$error_details);
    throw exception('HiveException', "\n".$error_details);
  }

  return 1;
}

sub write_output {
  my $self        = shift;
  my $job_id      = $self->param('job_id');
  my $output_file = $self->param('__output_file');

  my $content     = file_get_contents($output_file, sub { s/\R/\r\n/r });  
  my @del_files   = ($self->param('__log_file'), $self->param('__trim_file'), $self->param('__trim_file').".tbi", $self->param('__sample_panel'));
  
  # removing files (input and log files) to free up space
  for my $file (@del_files) {
    unlink $file if (-f $file);      
  }
  
  #if there is some results in the output file (not just the header in the file)
  if(scalar(split('\n',$content)) > 1) {
    $self->save_results($job_id, {}, [{"dummy" => "Allele frequency results obtained"}]); #for now storing dummy results as the output is stored in an output file
  }

  return 1;
}

1;
