#!/usr/bin/python

# -*- coding: ut
# Copyright: (c) 2020, Eshton Brogan
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

ANSIBLE_METADATA = {'metadata_version': '1.1',
'status': ['preview'],
'supported_by': 'community'}

DOCUMENTATION = r'''
---
module: win_gpo_link
short_description: Sets up a GPO link.
description:
  - Can link a GPO to the target specified.
options:
  name:
    description:
      - The name of the GPO to manage the link for.
    required: yes
    type: str
  state:
    description:
      - When C(yes), the link will be created.
      - When C(no), the link will be removed.
    choices:
      - absent
      - present
    default: present
    type: str
  enforced:
    description:
      - Whether the link will be enforced or not.
    type: bool
  enabled:
    description:
      - Whether the link will be enabled or not.
    type: bool
  target:
    description:
      - The LDAP path of the target to link the GPO to.
      - When not specified, this will be the whole domain.
    type: str
  wmi_filter_name:
    description:
      - Name of WMIFilter to be attached to the GPO Being linked
    type: str
author:
  - Jordan Borean (@jborean93)
  - Eshton Brogan
'''

EXAMPLES = r'''
- name: link and enable GPO root domain
    win_gpo_link:
      name: test-gpo
      state: present
      enforced: yes
      enabled: yes

- name: remove the GPO link for test-gpo on the root domain
  win_gpo_link:
    name: test-gpo
    state: absent

- name: link the GPO test-gpo to the Servers OU container
  win_gpo_link:
    name: test-gpo
    state: present
    target: OU=Server,DC=domain,DC=local
'''

RETURN = r'''
'''
