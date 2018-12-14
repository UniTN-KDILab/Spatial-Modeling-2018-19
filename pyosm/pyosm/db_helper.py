import logging

from pyosm.osm_elements import OSMNode, OSMWay, OSMRelation
from pyosm.db_handler import get_osm_db_connection, merge_relations_with, merge_ways_nodes

logger = logging.getLogger("osm.dbhelper")
logger.addHandler(logging.NullHandler())

class OSMDBHelper:

    def __init__(self, db_filename):
        self.db_filename = db_filename
        self.connection = None
        # store entries
        self._elements = []
        self._memberships = []
        self._batch_size = 1000

    def connect(self):
        self.connection = get_osm_db_connection(self.db_filename)

    def set_batch_size(self, value):
        new_batch_size = int(value)
        if new_batch_size <= 0:
            raise ValueError("Batch size must be at least 1.")
        self._batch_size = new_batch_size

    def save_osm_element(self, element):
        if isinstance(element, OSMNode):
            self.save_node(element)
        elif isinstance(element, OSMWay):
            self.save_way(element)  
        elif isinstance(element, OSMRelation):
            self.save_relation(element)
        # check if it's time to flush data to the db
        if len(self._elements) > self._batch_size or\
           len(self._memberships) > self._batch_size:
            self._insert_items()
            self._elements = []
            self._memberships = []
      
    def save_node(self, node):
        data = (node.alt_id, node.id, node.lat, node.lon, str.join(",", node.tags))
        self._elements.append(data)
        
    def save_way(self, way):
        data = (way.alt_id, way.id, None, None, str.join(",", way.tags))
        self._elements.append(data)
        for node_id in way.get_elements():
            self.save_membership(way.alt_id, node_id)

    def save_relation(self, relation):
        data = (relation.alt_id, relation.id, None, None, str.join(",", relation.tags))
        self._elements.append(data)
        for member_id in relation.get_elements():
            self.save_membership(relation.alt_id, member_id)

    def save_membership(self, container_id, contained_id):
        data = (container_id, contained_id)
        self._memberships.append(data)

    def _insert_items(self):
        with self.connection as conn:
            sql_elements = """INSERT INTO elements(id, el_id, lat, lon, tags) VALUES(?,?,?,?,?);"""
            sql_memberships = """INSERT INTO memberships (container, contained) VALUES (?, ?);"""
            cursor = conn.cursor()
            cursor.executemany(sql_elements, self._elements)
            cursor.executemany(sql_memberships, self._memberships)
            conn.commit()
            logger.info("Batch commit successful.")

    def merge_tags(self):
        merge_relations_with(self.connection, "r")
        logger.info("Merged relations in relations")
        merge_relations_with,(self.connection, "w")
        logger.info("Merged ways in relations")
        merge_relations_with(self.connection, "n")
        logger.info("Merged nodes in relations")
        merge_ways_nodes(self.connection)
        logger.info("Merged nodes in ways")
