import logging

logger = logging.getLogger("osm.elements")
logger.addHandler(logging.NullHandler())

class OSMElement:

  NODE_PREFIX = "n"
  WAY_PREFIX  = "w"
  RELATION_PREFIX = "r"
  
  def __init__(self, id):
    self.id = id
    self.tags = []

  def add_tag(self, tag):
    self.tags.append(tag)

class OSMNode(OSMElement):
  def __init__(self, id, lat, lon):
    super().__init__(id)
    self.alt_id = OSMElement.NODE_PREFIX + str(self.id)
    self.lat = lat
    self.lon = lon

  def __str__(self):
    return "OSMNode id: {}, alt_id: {}, lat: {}, lon: {}"\
      .format(self.id, self.alt_id, self.lat, self.lon)


class OSMWay(OSMElement):
  def __init__(self, id):
    super().__init__(id)
    self.alt_id = OSMElement.WAY_PREFIX + str(self.id)
    self.nodes = []

  def add_element(self, node_id):
    self.nodes.append(OSMElement.NODE_PREFIX + node_id)

  def get_elements(self):
    return self.nodes
    
  def __str__(self):
    return "OSMWay id: {}, alt_id: {}"\
      .format(self.id, self.alt_id)

    
class OSMRelation(OSMElement):
  def __init__(self, id):
    super().__init__(id)
    self.alt_id = OSMElement.RELATION_PREFIX + str(self.id)
    self._members = []

  def add_element(self, id, type_):
    if type_ == "node":
      self._members.append(OSMElement.NODE_PREFIX + id)
    elif type_ == "way":
      self._members.append(OSMElement.WAY_PREFIX + id)
    elif type_ == "relation":
      self._members.append(OSMElement.RELATION_PREFIX + id)
    else:
      logger.warning("Unknown member type: {}".format(type_))

  def get_elements(self):
    return self._members
      
  def __str__(self):
    return "OSMRelation id: {}, alt_id: {}"\
      .format(self.id, self.alt_id)
