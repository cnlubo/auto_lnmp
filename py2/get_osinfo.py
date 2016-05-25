#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Author: ak47
# @Date:   2016-02-19 18:02:34
# @Last Modified by:   ak47
# @Last Modified time: 2016-02-19 18:26:45
import getpass
import os
import pwd

def Get_user():


   return getpass.getuser()


if __name__ == "__main__":
   os_user = Get_user()
   print getpass.getuser()

