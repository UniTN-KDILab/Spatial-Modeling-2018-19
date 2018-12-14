source=filtered_trentino_aas_25_10_18.osm
out_filt_file=transportation_filt_trentino.osm
filt_tags_file=filt_tags_transportation
out_all_nodes_file=nodes_transportation_filt_trentino.osm
out_id_loc_csv=nodes.csv

# extract only entities having at least one tags related to transportation means
osmium tags-filter --overwrite $source -F osm -e $filt_tags_file -f osm -o $out_filt_file -R
osmfilter $out_filt_file --parameter-file=filtering_parameters  > $out_all_nodes_file

# @deprecated
# save id, lat, lon, name to a csv file, in order to obtain information by using
# a reverse geocoder
# osmconvert $out_all_nodes_file --out-csv --csv-headline --csv-separator=";" --csv="@id @lat @lon name" -o=$out_id_loc_csv
