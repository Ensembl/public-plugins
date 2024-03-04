# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2024] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ticket table patch
ALTER TABLE `ticket` ADD `release` INT(10) NULL DEFAULT NULL AFTER `site_type`;
ALTER TABLE `ticket` CHANGE `status` `status` ENUM('Current','Expiring','Expired','Deleted') NOT NULL DEFAULT 'Current';

# job table patch
ALTER TABLE `job` CHANGE `status` `status` ENUM('awaiting_dispatcher_response','awaiting_user_response','done','deleted') NOT NULL DEFAULT 'awaiting_user_response';
