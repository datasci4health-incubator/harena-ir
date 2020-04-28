import pysolr

solr_server_url = 'http://localhost:8983/solr/'
solr_collection = "mesh"
solr = pysolr.Solr(solr_server_url + solr_collection)

#query = str(input())
query = "Myocardial Infarction"
results = solr.search(query, rows=100)

print("Found {0} documents".format(len(results)))

for result in results:
    print(result["ConceptName"][0], "\n")
