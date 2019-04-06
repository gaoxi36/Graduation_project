#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (c) 2019 ob767, Inc. All Rights Reserved
#

from Ci_Test import CI_TEST
import time

if __name__ == '__main__':

    email_name = '347699598@qq.com'

    CI_TEST('Local', '石家庄节点', email_name)
    # time.sleep(10)
    # CI_TEST('Local', '全量回归', email_name)