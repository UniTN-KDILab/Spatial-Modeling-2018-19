# Spatial Modelling Extension

In the root folder it is possible to find:

* the data folder containing the data used by scripts to create individuals in protege
* the `scripts` folder, containing the R script files used to process data contained
  in the `data` folder.
* the `cellfie_rules.json` file contains the transformation rules cellfie
  has to perform in order to import individuals in protege.
* the `graphs` folder contains graphml files created using yED for both
  the informal and formal model used for the task.
* the folder `data_processing_resources` contains help files and bash scripts used
  to collect data for the project, including osm_scripts,
  set of commands and generalised info about osm file processing
  both with `osm-tools` and `osmium`, in addition to useful code snippets
* pyosm, a python library used to build a SQLite db out of an .osm file.
  Which we though to use to obtain tags out of the various OSM entities, in
  scenarios where `osmium` and `osm-tools` **seem not** to do the job.

  PyOSM has been deprecated in favour of other ways to process OSM data.


____

## PyOSM(@Deprecated)

In the folder pyosm there is the Python3 code used to build, populate
and manage the SQLite database.

Within the folder the program can be called by issuing the `pyosm` command,
following the helper.

### Building the DB

To build the DB pick the `.osm` where nodes should be
taken from and placed into the `/pyosm` folder starting
from the git project root directory. Then issue the command:

```bash
python3 pyosm.py <my_file.osm> <destination_db.db>
```

This will create the SQLite `destination_db.db` file and
populate it.

### Merging nodes

In order for nodes to inherit tags from the relations and the
ways they are in, the `pyosm` program can be
used. Given the db file previously populated, the
following command will perform the merging job:

```bash
python3 pyosm.py -m <populated_osm.db>
```

