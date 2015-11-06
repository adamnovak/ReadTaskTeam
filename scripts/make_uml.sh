#!/usr/bin/env bash
set -ex

# Script to turn Avro IDL into a UML diagram. Requires Python 2.7, GNU sed,
# and GraphViz. Run from the contrib folder:
#
# $ scripts/make_uml.sh
#
# Excludes the methods files.
#
# The resulting UML will show up in target/generated-diagrams/uml.svg
#
# If the edge autodetection fails, add new ID reference edges to 
# scripts/extra_edges.dot

if [ -d scripts ]
then
    # Make sure we are in the contrib directory.
    cd scripts
fi

# Where do we put the UML?
OUT_DIR=../target/generated-diagrams

if [ ! -f avro-tools.jar ]
then

    # Download the Avro tools
    curl -o avro-tools.jar  http://www.us.apache.org/dist/avro/avro-1.7.7/java/avro-tools-1.7.7.jar
fi

# Make a directory for all the .avpr files
mkdir -p "${OUT_DIR}"

for AVDL_FILE in ../src/main/resources/avro/*.avdl
do
    # Make each AVDL file into a JSON AVPR file.

    # Get the name of the AVDL file without its extension or path
    SCHEMA_NAME=$(basename "$AVDL_FILE" .avdl)

    # Decide what AVPR file it will become.
    AVPR_FILE="../target/schemas/${SCHEMA_NAME}.avpr"

    # Compile the AVDL to the AVPR
    java -jar avro-tools.jar idl "${AVDL_FILE}" "${AVPR_FILE}"

done

# Now make the DOT file
./avpr2uml.py `ls ../target/schemas/* | grep -v method` --dot ${OUT_DIR}/uml.dot


# Knock off the last line, which closed the graph.
mv ${OUT_DIR}/uml.dot ${OUT_DIR}/uml.dot.bak
cat ${OUT_DIR}/uml.dot.bak | sed '$ d' > ${OUT_DIR}/uml.dot
rm ${OUT_DIR}/uml.dot.bak

# Add in any manually defined ID reference edges
cat >> ${OUT_DIR}/uml.dot <<EOF
// Extra ID reference edges that we don't autodetect
// Use fully qualified names, and replace dots with underscores

// Feature has a "parentId"
org_ga4gh_models_Feature -> org_ga4gh_models_Feature

// Individual has a "groupId"
org_ga4gh_models_Individual -> org_ga4gh_models_IndividualGroup
EOF

# Add the closing brace back
echo "}" >> ${OUT_DIR}/uml.dot

# Make the picture
dot ${OUT_DIR}/uml.dot -T svg -o ${OUT_DIR}/uml.svg


