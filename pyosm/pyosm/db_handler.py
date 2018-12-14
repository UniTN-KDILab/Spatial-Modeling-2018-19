import sqlite3
import os

db_create_schema = """
DROP TABLE IF EXISTS elements;
DROP TABLE IF EXISTS memberships;

CREATE TABLE IF NOT EXISTS elements (
  id varchar(32) PRIMARY KEY,
  el_id varchar(32) NOT NULL,
  lat varchar(32) DEFAULT NULL,
  lon varchar(32) DEFAULT NULL,
  tags TEXT DEFAULT ""
);

CREATE TABLE IF NOT EXISTS memberships (
  container varchar(32) NOT NULL,
  contained varchar(32) NOT NULL,
  FOREIGN KEY (container) REFERENCES elements (id), 
  FOREIGN KEY (contained) REFERENCES elements (id)
);
"""

def get_osm_db_connection(db_file=None):
    if db_file is None:
        db_file = ":memory:"
    try:
        empty = False
        if not os.path.isfile(db_file):
            empty = True
        conn = sqlite3.connect(db_file)
        if empty:
            create_schema(conn, db_create_schema)
        return conn
    except sqlite3.Error as e:
        print(e)
    return None

def create_schema(conn, create_statements):
    try:
        cursor = conn.cursor()
        cursor.executescript(create_statements)
        conn.commit()
    except sqlite3.Error as e:
        print(e)

# ------------------------------------------------

def delete_memberships(conn, entries):
    cursor = conn.cursor()
    cursor.executemany("DELETE FROM memberships WHERE container=? AND contained=?",\
                     entries)

def update_element_tag(conn, entries):
    cursor = conn.cursor()
    cursor.executemany("UPDATE elements SET tags = ? WHERE id = ?", entries)
    

def merge_relations_with(conn, osm_element_prefix, batch_size=1000):
    cursor = conn.cursor()
    cursor.execute("""SELECT container.id, contained.id, contained.tags, container.tags
                 FROM elements container INNER JOIN memberships ON container.id = memberships.container
                 INNER JOIN elements contained ON contained.id = memberships.contained
                 WHERE memberships.container LIKE "r%" AND memberships.contained LIKE "{}%"
                 ORDER BY memberships.container ASC""".format(osm_element_prefix))
    update_list = []
    for container_id, contained_id,\
        contained_tags, container_tags in cursor:
        merged_tags = contained_tags + ',"relation_{}" : {{ {} }}'.format(container_id, container_tags)
        update_list.append((merged_tags, contained_id))
        if len(update_list) > batch_size:
            update_element_tag(conn, update_list)
            update_list = []
    update_element_tag(conn, update_list)
    conn.commit()

def merge_ways_nodes(conn, batch_size=1000):
    cursor = conn.cursor()
    cursor.execute("""SELECT container.id, contained.id, contained.tags, container.tags
                 FROM elements container INNER JOIN memberships ON container.id = memberships.container
                 INNER JOIN elements contained ON contained.id = memberships.contained
                 WHERE memberships.container LIKE "w%" AND memberships.contained LIKE "n%"
                 ORDER BY memberships.container ASC""")
    update_list = []
    for container_id, contained_id,\
        contained_tags, container_tags in cursor:
        merged_tags = contained_tags + ',"way_{}" : {{ {} }}'.format(container_id, container_tags)
        update_list.append((merged_tags, contained_id))
        if len(update_list) > batch_size:
            update_element_tag(conn, update_list)
            update_list = []
    update_element_tag(conn, update_list)
    conn.commit()
          
