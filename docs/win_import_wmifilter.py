#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2019, Eshton Brogan <eshton.brogan@gmail.com>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'private'}

DOCUMENTATION = r'''
---
module: win_import_wmifilter
version_added: "2.8"
short_description: Import Group WMIFilters 
description:
     - Can import Windows Domain Group Policy WMIFilters.
options:
  mof_file:
    description:
      - Path to WMIFilter .mof file
    type: str
    required: yes
notes:
- This must be run on a host that has the ActiveDirectory powershell module installed.
 
author:
    - Eshton Brogan
    - Chris Kennedy
    - Frank Armstrong
'''

EXAMPLES = r'''
- name: Import WMI Filters from GPO Backup
  win_import_wmifilter:
    mof_file: 'C:\TEMP\backups\Windows Server 2016.mof'

'''

RETURN = r'''
'''
