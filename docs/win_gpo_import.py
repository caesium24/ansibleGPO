#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2019, Eshton Brogan <eshton.brogan@gmail.com>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'private'}

DOCUMENTATION = r'''
---
module: win_gpo_import
version_added: "2.8"
short_description: Import Group Policy Objects from Backup 
description:
     - Can import Windows Domain Group Policy Objects from backup files.
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
  state:
    description:
      - If C(state=present) GPOs will be imported
      - If C(state=absent) GPO will be removed
    type: str
    choices: [ absent, present ]
    default: present
  gpo:
    description:
      - Name of group policy object to be removed - Only utilized when removing
    type: str
  domain:
    description:
      - Will set target domain for GPOs to be imported into
    type: str
notes:
  - This must be run on a host that has the ActiveDirectory powershell module installed.
 
author:
    - Eshton Brogan
'''

EXAMPLES = r'''
- name: Import Backup Group Policy Objects to example.com
  win_gpo_import:
    path: c:\backups
    state: present
    domain: example.com
    migration_table: 'c:\temp\example.migtable'

- name: Import Backup Group Policy Objects
  win_gpo_import:
    gpo_name: "test gpo"
    state: absent
    

'''

RETURN = r'''
'''
