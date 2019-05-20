#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (c) 2019 ob767, Inc. All Rights Reserved
#

from Ci_Test import CI_TEST

if __name__ == '__main__':

    email_name = '347699598@qq.com'

    # CI_TEST('Local', '上海节点', email_name)
    # CI_TEST('Online', '昆明节点', email_name)
    CI_TEST('Online', '全量回归', email_name)