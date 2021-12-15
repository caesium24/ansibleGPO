#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2021, Eshton Brogan
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'private'}

DOCUMENTATION = r'''
---
module: win_generate_mig_table
version_added: "2.9"
short_description: Creates a Group Policy Migration table based on backed up Group Policies
description:
     - Can create a Group Policy Migration table file based on backed up Group Policies
options:
  path:
    description:
      - Path to GPO backup folder
    type: str
    required: yes
  migration_table:
    description:
      - Path to Migration Table
    type: str
    required: yes
notes:
  - This must be run on a host that has the ActiveDirectory powershell module installed.
 
author:
    - Eshton Brogan
'''

EXAMPLES = r'''
- name: Generate Migration Table
  win_generate_mig_table:
    path: c:\backups
    migration_table: 'c:\temp\example.migtable'    

'''

RETURN = r'''
'''
