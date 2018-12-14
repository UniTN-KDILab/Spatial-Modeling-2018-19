import requests
import csv
import json
import time
import logging

from requests import RequestException

logger = logging.getLogger("reverse.geocoder")

class GeocoderAbort(Exception): pass

end_point = "https://nominatim.openstreetmap.org/reverse"
headers = {
    "User-Agent" : "transportation reverse-geocoding",
    "From" : "diego.lobba@studenti.unitn.it"
}

def send_request(osm_id, end_point, headers):
    params = {
        "format" : "jsonv2",
        "osm_type" : "N",
        "osm_id" : osm_id,
        "zoom" : 18,
        "addressdetails" : 1
    }
    response = requests.get(end_point, headers=headers, params=params)
    # if Nominating is not able to geocode by using the id
    # then insert the osm node by hand. This will be useful
    # later.
    response_json = response.json()
    if "osm_id" not in response_json:
        response_json["osm_id"] = osm_id
        logger.info("Unable to reverse-geocode node {}".format(osm_id))
    else:
        logger.info("Retrieved successfully node {}".format(osm_id))
    return response_json

def make_requests(source_file, dest_file, end_point, headers):
    with open(dest_file, "w") as dest_fh:
        with open(source_file) as csv_file:
            csv_reader = csv.reader(csv_file, delimiter=';')
            next(csv_reader, None) # skip headers
            for row in csv_reader:
                try:
                    osm_id = row[0]
                    response_json = send_request(osm_id, end_point, headers)
                    dest_fh.write(json.dumps(response_json) + "\n")
                    # do not flood Nominatim, respect the policy use
                    time.sleep(1)
                except RequestException:
                    logger.exception("Connection error encounter"
                                     " during retrieval of node {}".format(osm_id))
                    raise GeocoderAbort()

def csv_output(rev_geocode_file, dest_csv_file):
    csv_fields = (
        "osm_id",
        "road",
        "suburb",
        "city",
        "county",
        "state",
        "postcode",
        "country",
        "country_code"
    )
    with open(dest_csv_file, "w") as dest_fh:
        csv_writer = csv.writer(dest_fh, delimiter=";", quoting=csv.QUOTE_MINIMAL)
        csv_writer.writerow(csv_fields)
        with open(rev_geocode_file, "r") as source_fh:
            for line in source_fh:
                json_response = json.loads(line)
                osm_id = json_response["osm_id"]
                fields = [osm_id]
                if "address" in json_response:
                    json_response = json_response["address"]
                    # retrieve required fields
                    for field in csv_fields[1:]:
                        fields.append(json_response[field])
                    csv_writer.writerow(fields)
                else:
                    logger.info("No information found for node {}".format(osm_id))


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    try:
        make_requests("small_nodes.csv", "small_batch.json", end_point, headers)
        csv_output("small_batch.json", "out.csv")
    except (GeocoderAbort, KeyboardInterrupt, SystemExit):
        logger.exception("The reverse geocoder has been interrupted abnormally")
        logger.warning("All files have been correctly closed and saved")



