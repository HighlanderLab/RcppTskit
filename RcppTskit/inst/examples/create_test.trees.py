import msprime
import tskit
import os

# Generate a tree sequence for testing
ts = msprime.sim_ancestry(
    samples=80, sequence_length=1e4, recombination_rate=1e-4, random_seed=42
)
ts = msprime.sim_mutations(ts, rate=1e-2, random_seed=42)
ts
print(ts)
ts.num_provenances  # 2
ts.num_populations  # 1
ts.num_migrations  # 0
ts.num_individuals  # 80
ts.num_samples  # 160
ts.num_nodes  # 344
ts.num_edges  # 414
ts.num_trees  # 26
ts.num_sites  # 2376
ts.num_mutations  # 2700
ts.sequence_length  # 10000.0
ts.time_units  # 'generations'

ts.metadata  # b''
type(ts.metadata)  # bytes
len(ts.metadata)  # 0
# ts.metadata.shape # 'bytes' object has no attribute 'shape'

ts.metadata_schema
# empty

ts.tables.populations.metadata  # array() ...
type(ts.tables.populations.metadata)  # numpy.ndarray
len(ts.tables.populations.metadata)  # 33
ts.tables.populations.metadata.shape  # (33,)

schema = ts.tables.populations.metadata_schema
# {"additionalProperties":true,"codec":"json","properties":{"description":{"type":["string","null"]},"name":{"type":"string"}},"required":["name","description"],"type":"object"}
schema.asdict()
# OrderedDict([('additionalProperties', True),
#              ('codec', 'json'),
# ...

ts.tables.migrations.metadata  # array() ...
type(ts.tables.migrations.metadata)  # numpy.ndarray
len(ts.tables.migrations.metadata)  # 0
ts.tables.migrations.metadata.shape  # (0,)

ts.tables.individuals.metadata  # array() ...
type(ts.tables.individuals.metadata)  # numpy.ndarray
len(ts.tables.individuals.metadata)  # 0
ts.tables.individuals.metadata.shape  # (0,)

os.getcwd()
os.chdir("RcppTskit")
ts.dump("inst/examples/test.trees")
# ts = tskit.load("test.trees")

# Create a second tree sequence with metadata in some tables
ts2_tables = ts.dump_tables()
len(ts2_tables.metadata)
ts2_tables.metadata = tskit.pack_bytes('{"seed": 42, "note": "ts2"}')

# Create a second tree sequence with metadata in some tables
basic_schema = tskit.MetadataSchema({"codec": "json"})
# {"codec":"json"}

tables = ts.dump_tables()

tables.metadata_schema = basic_schema
# {"codec":"json"}
tables.metadata = {"mean_coverage": 200.5}
# {'mean_coverage': 200.5}

tables.individuals.metadata_schema = tskit.MetadataSchema(None)
tables.individuals.metadata
len(tables.individuals)  # 80
tables.individuals[0]
# IndividualTableRow(flags=0, location=array([], dtype=float64), parents=array([], dtype=int32), metadata=b'')
tables.individuals[0].metadata
# b''
tables.individuals[79]
# ...
tables.individuals[79].metadata
# b''
tables.individuals.add_row(metadata=b"SOME CUSTOM BYTES #!@")
tables.individuals[80]
# IndividualTableRow(flags=0, location=array([], dtype=float64), parents=array([], dtype=int32), metadata=b'SOME CUSTOM BYTES #!@')
tables.individuals[80].metadata
# b'SOME CUSTOM BYTES #!@'

ts = tables.tree_sequence()
ts
ts.num_individuals  # 81

ts.metadata  # {'mean_coverage': 200.5}
type(ts.metadata)  # dict
len(ts.metadata)  # 1
ts.metadata_schema  # {"codec":"json"}
ts.metadata_schema

ts.tables.individuals.metadata  # array() ...
type(ts.tables.individuals.metadata)  # numpy.ndarray
len(ts.tables.individuals.metadata)  # 21
ts.tables.individuals.metadata.shape  # (21,)

ts.dump("inst/examples/test2.trees")

tables = ts.dump_tables()
tables.metadata_schema = tskit.MetadataSchema(None)
tables.metadata
# b'{"mean_coverage":200.5}'
ts = tables.tree_sequence()
ts.metadata
len(ts.metadata)  # 23
