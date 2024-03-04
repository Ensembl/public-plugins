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


# ticket_type table
# -----------------

CREATE TABLE `ticket_type` (
  `ticket_type_name` varchar(32) NOT NULL DEFAULT '',
  `ticket_type_caption` varchar(64) NOT NULL DEFAULT '',
  PRIMARY KEY (`ticket_type_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


# ticket table
# ------------

CREATE TABLE `ticket` (
  `ticket_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ticket_name` varchar(16) NOT NULL DEFAULT '',
  `ticket_type_name` varchar(32) NOT NULL DEFAULT '',
  `owner_id` varchar(32) NOT NULL,
  `owner_type` enum('user','session') NOT NULL DEFAULT 'session',
  `visibility` enum('private','public') NOT NULL DEFAULT 'public',
  `created_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `modified_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `status` enum('Current','Expiring','Expired','Deleted') NOT NULL DEFAULT 'Current',
  `site_type` varchar(255) NOT NULL DEFAULT '',
  `release` int(10) DEFAULT NULL,
  PRIMARY KEY (`ticket_id`),
  UNIQUE KEY `ticket_name` (`ticket_name`),
  KEY `create_time` (`created_at`),
  KEY `update_time` (`modified_at`),
  KEY `ticket_type_name` (`ticket_type_name`),
  CONSTRAINT `ticket_ibfk_1` FOREIGN KEY (`ticket_type_name`) REFERENCES `ticket_type` (`ticket_type_name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


# job table
# ---------

CREATE TABLE `job` (
  `job_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ticket_id` int(10) unsigned NOT NULL,
  `species` varchar(255) NOT NULL,
  `assembly` varchar(255) NOT NULL,
  `job_number` int(10) DEFAULT NULL,
  `job_data` text NOT NULL,
  `job_desc` varchar(500) DEFAULT NULL,
  `job_dir` varchar(255) DEFAULT NULL,
  `status` enum('awaiting_dispatcher_response','awaiting_user_response','done','deleted') NOT NULL DEFAULT 'awaiting_user_response',
  `dispatcher_class` varchar(255) DEFAULT NULL,
  `dispatcher_reference` varchar(255) DEFAULT NULL,
  `dispatcher_data` text,
  `dispatcher_status` enum('not_submitted','queued','submitted','running','done','failed','deleted','no_details') NOT NULL DEFAULT 'not_submitted',
  `modified_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`job_id`),
  KEY `ticket_id` (`ticket_id`),
  CONSTRAINT `job_ibfk_1` FOREIGN KEY (`ticket_id`) REFERENCES `ticket` (`ticket_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


# result table
# ------------

CREATE TABLE `result` (
  `result_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `job_id` int(10) unsigned NOT NULL,
  `result_data` text,
  `created_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`result_id`),
  KEY `job_id` (`job_id`),
  CONSTRAINT `result_ibfk_1` FOREIGN KEY (`job_id`) REFERENCES `job` (`job_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


# job_message table
# -----------------

CREATE TABLE `job_message` (
  `job_message_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `job_id` int(10) unsigned NOT NULL,
  `display_message` varchar(500) DEFAULT NULL,
  `exception` text,
  `data` text,
  `fatal` smallint(1) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`job_message_id`),
  KEY `job_id` (`job_id`),
  CONSTRAINT `job_message_ibfk_1` FOREIGN KEY (`job_id`) REFERENCES `job` (`job_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
