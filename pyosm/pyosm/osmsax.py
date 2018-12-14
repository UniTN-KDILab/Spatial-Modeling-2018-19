import json
import logging
import xml.sax

from pyosm.osm_elements import OSMNode, OSMWay, OSMRelation

logger = logging.getLogger("osm.saxparser")
logger.addHandler(logging.NullHandler())

def parse_osm(source, action):
  xml.sax.parse(source, OSMContentHandler(action))
            
class OSMContentHandler(xml.sax.ContentHandler):
  
  def __init__(self, action):
    xml.sax.ContentHandler.__init__(self)
    self.elements = []
    self.current_osm_element = None
    self.managed_tags = ("member", "nd", "relation", "way", "node", "tag")
    self.element_tags = ("node", "way", "relation")
    # perform this action whenever an OSM
    # element has been completely processed (at its end)
    self.action = action
    
  def startElement(self, name, attrs):
    name = name.lower().strip()
    # store the current element into the buffer
    if name in self.element_tags and\
            self.current_osm_element is not None:
      self.elements.append(self.current_osm_element)
            
    if name == "node":
      id_ = attrs["id"]
      lat = attrs["lat"]
      lon = attrs["lon"]
      self.current_osm_element = OSMNode(id_, lat, lon)
    elif name == "way":
      id_ = attrs["id"]
      self.current_osm_element = OSMWay(id_)
    elif name == "relation":
      id_ = attrs["id"]
      self.current_osm_element = OSMRelation(id_)
    elif name == "tag":
      k = attrs["k"]
      v = attrs["v"]
      # delete the brackets, preserve the serialisation
      json_tag = json.dumps({k : v})[1:-1]
      self.current_osm_element.add_tag(json_tag)
    elif name == "nd":
      self.current_osm_element.add_element(attrs["ref"])
    elif name == "member":
      self.current_osm_element.add_element(attrs["ref"], attrs["type"])
    else:
      logger.warning("OSM tag ignored: {}".format(name))

  def endElement(self, name):
    if name in self.element_tags:
      # perform the action of the
      # OSMElement just processed
      # e.g:
      # * print it
      # * save it somewhere
      # * ...
      self.action(self.current_osm_element)
      if len(self.elements) > 0:
          self.current_osm_element = self.elements.pop()
      else:
          self.current_osm_element = None
  
  def characters(self, content):
      pass
