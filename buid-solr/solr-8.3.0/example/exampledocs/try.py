import pysolr
solr_server_url = 'http://localhost:8983/solr/'
solr_collection = "mesh"
solr = pysolr.Solr(solr_server_url + solr_collection)
results = solr.more_like_this(q='Myocardial Infarction', rows=2147483647)
for result in results:
	print(result["ConceptName"])
