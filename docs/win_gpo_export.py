#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2019, Eshton Brogan <eshton.brogan@gmail.com>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'private'}

DOCUMENTATION = r'''
---
module: win_gpo_export
version_added: "2.8"
short_description: Export Group Policy Objects to Backup 
description:
     - Can export Windows Domain Group Policy Objects to backup files.
options:
  path:
    description:
      - Path to GPO backup folder
    type: str
    required: yes
  gpo_name:
    description:
      - Name of group policy object to be exported
    type: str
    required: yes
notes:
  - This must be run on a host that has the ActiveDirectory and GroupPolicy powershell modules installed.
 
author:
    - Eshton Brogan
'''

EXAMPLES = r'''
- name: Import Backup Group Policy Objects
  win_gpo_export:
    path: 'C:\temp\ie-policies'
    gpo_name: "IE11 Security Policies"
    

'''

RETURN = r'''
'''
