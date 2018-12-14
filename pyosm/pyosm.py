#!/usr/bin/python3
import logging
import sys
import os

from pyosm.db_handler import get_osm_db_connection
from pyosm.db_helper import OSMDBHelper
from pyosm.osmsax import parse_osm


def populate_db(sourceFileName, db_filename):
    db_exists = False
    if os.path.isfile(db_filename):
        db_exists = True
    if db_exists:
        in_ = input("The db file will be erased, are you sure? [y/N]")
        override = False
        if in_.lower().strip()[0] == "y":
            override = True
        if override is True:
            os.remove(db_filename)
        else:
            print("DB file not overwritten, terminating...")
            sys.exit(0)
    try:
        dbhelper = OSMDBHelper(db_filename)
        dbhelper.set_batch_size(10000)
        dbhelper.connect()
        source = open(sourceFileName)
        save_action = lambda element: dbhelper.save_osm_element(element)
        parse_osm(source, save_action)
    finally:
        dbhelper.connection.close()
        source.close()

def merge_tags(db_filename):
    if not os.path.isfile(db_filename):
        print("The db file does not exist, terminating...")
        sys.exit(-1)
    try:
        dbhelper = OSMDBHelper(db_filename)
        dbhelper.set_batch_size(10000)
        dbhelper.connect()
        dbhelper.merge_tags()
    finally:
        dbhelper.connection.close()

        
usage_string =\
"""pyosm usage:
* build the db reading from source and inserting into destination.db

  pyosm -b <source.osm> <destination.db>

* merge tags of the given db (NB: the operation is not idempotent)

  pyosm -m <osm.db>
"""
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    arglen = len(sys.argv) - 1 # exlude program name
    try:
        if sys.argv[1] == "-b":
            populate_db(sys.argv[2], sys.argv[3])
        elif sys.argv[1] == "-m":
            merge_tags(sys.argv[2])
        else:
            raise ValueError()
    except (IndexError, ValueError):
        print(usage_string)
