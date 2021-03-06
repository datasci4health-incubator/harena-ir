# harena-ir
Information Retrieval for Harena.
Caio Emanuel Rhoden - RA214129
Enzo Hideki Iwata - RA215394

## Introdução
A recuperação de informação é um tema amplamente estudado e utilizado na computação, nesse projeto em específico o objetivo é usar dessa ferramenta para, através da entrada de conceitos relacionados à área da saúde, retornar o resultado que melhor se aplica ao item pesquisado, usando o  MESH(Medical Subject Headings) e solr para isso.

## Guia
### Instalação do Solr
Instale em [solr.zip](http://ftp.unicamp.br/pub/apache/lucene/solr/8.3.1/solr-8.3.1.zip), e extraia-o

### Iniciando o solr
Para iniciar o solr precisamos estar dentro do diretório "solr-8.3.1", dele digitamos

```bin/solr start```

Deverá aparecer algo desse tipo:

```*** [WARN] *** Your open file limit is currently 1024.  
 It should be set to 65000 to avoid operational disruption. 
 If you no longer wish to see this warning, set SOLR_ULIMIT_CHECKS to false in your profile or solr.in.sh
*** [WARN] ***  Your Max Processes Limit is currently 14152. 
 It should be set to 65000 to avoid operational disruption. 
 If you no longer wish to see this warning, set SOLR_ULIMIT_CHECKS to false in your profile or solr.in.sh
Waiting up to 180 seconds to see Solr running on port 8983 [/]  
Started Solr server on port 8983 (pid=20337). Happy searching!
```
### Começando a editar o solr
Para usarmos o solr precisamos criar um "core", ele será o nome do dicionário. Para isso usaremos o seguinte comando

```bin/solr create -c mesh -p 8983```

Devrá aparecer essa mensagem: 

```Created new core 'mesh'```

Este comando cria um core chamado mesh na porta 8983 do computador, então para acessarmos esse dicionário de busca precisamos acessar a porta local 8983 do computador.

Com o core criado é necessário editar a "inteligência" da busca, ela ficará localizada seguindo o seguinte caminho: ```server/solr/mesh/conf``` o nome do arquivo é ```managed-schema``` e será explicado em detalhes mais a frente. Neste arquivo declaramos os tipos de "fields" que serão usados nos textos, assim como seus formatos.

O banco de dados do mesh ficará no diretório ```example/exampledocs```.

### Banco de dados
Para adicionarmos novos dados ao nosso core precisamos deixar esses dados num formato xml específico, para isso primeiramente pegaremos os dados do mesh.

#### Instalando o Mesh
O banco de dados do mesh que iremos usar estará no formato XML. Entrando no link a seguir faça o download no [desc2020.zip](https://github.com/Iwazo8700/mesh-annotation/blob/master/buid-solr/desc2020.zip), vale lembrar que os dados do MESH são disponibilizados gratuitamente e possuem uma ampla documentação sobre sua estrutura para quem quiser conhecer mais a fundo

#### Edição do Mesh
Com a base instalada vamos editar esse xml para um xml que possa ser lido pelo solr e ser interpretado como informação, o jeito mais fácil que encontramos para fazer isso foi usando xpath e xquery.
O formato do arquivo que devemos chegar é 
```<add>
     <doc>
     <field name=_nome_ boost=_float_>_valor_</field>
     ...
     <\doc>
     ...
   <\add>
```
onde o boost é opcional.

Para transformar o mesh em um xml válido usamos o pragrama [parseXML2XMLsolr.xq](https://github.com/datasci4health-incubator/harena-ir/blob/master/solr-8.3.1/parseXML2XMLsolr.xq), nele transformamos os seguintes dados em fields, podendo adicionar boosts para priorização de campos determinados:
* DescriptorUI (ID associado a um elemento do MESH)
* ConceptName (nome de um elemento do MESH, como doenças por exemplo)
* ConceptUI (ID relacionada a um nome de um elemento do MESH)
* EntryTerm (termos associados ao elemento, como sinônimos)
* PreviousIndexing (mostra qual categoria o elemento está associado, por exemplo, antibióticos)
* Annotation (informações adicionais sobre o elemento)
* ScopeNote (Definição do elemento)
* DateCreated (Data em que o elemento foi adicionado)

O arquivo .xml obtido deve ser salvo no seguinte endereço: solr-8.3.1/example/exampledocs, sendo no nosso caso o [XMLsolr.xml](https://github.com/datasci4health-incubator/harena-ir/blob/master/solr-8.3.1/example/exampledocs/XMLsolr.xml)


#### Xpath e Xquery(parseXML2XMLsolr.xq)
A lógica usada para fazer esse programa foi usando caminhos que cheguem aonde queremos aplicando a "/"para passar de uma camada para outra até chegar no termo desejado ou quando existia um termo único usar a "//" para ir direto ao ponto. O xquery usamos no momento e que se tinha um termo que desejavamos inserir, mas ele não era simples e precisava pegar esse termo várias vezes, para isso usamos o conceito de for do xquery. Tudo que precisamos fazer nesse ponto foi codificado na xbase, um editor especializado nesse tipo de situação.

```let $mesh := doc("/home/USER/Documentos/Docker/desc2020.xml")

return
<add>
{
  for $d in ($mesh//DescriptorRecord)
  return
  <doc>
    <field name="ScopeNote" boost="2.0">{$d//ScopeNote/text()}</field>
  </doc>
}
</add>
```

Nesse trecho por exemplo, definimos o caminho do desc2020.xml em $mesh, printamos o \<add\>, criamos um for que passa por cada DescriptorRecord do arquivo, dentro de cada DescriptorRecord printamos um \<doc\>, um \<field name="ScopeNote" boost="2.0"\>, o texto do ScopeNote desse DescriptorRecord e fechamos o field com \<\\field\>, finalizando esse doc com o <\doc>. Depois de passar por todos DescriptorRecord, finalizamos o documento com o \<\\add\>, adquirindo um documento que começa com <add>, termina com \<\\add\>, e dentro desse add vários \<doc\> e \<\\doc\>, cada um com seu ScopeNote. Lembrando que o boost é opcional e só será usado para definir uma prioridade de field na hora da busca.


### Managed-Schema
#### Field
Nesse arquivo, [managed_shcema](https://github.com/datasci4health-incubator/harena-ir/blob/master/solr-8.3.1/server/solr/mesh/conf/managed-schema) (nessa arquivo em questão já com todas as declarações),  temos varios tipos de classes a serem declaradas, mas para criarmos um campo de busca focamos na classe \<field\>, nela iremos declarar quais tipos de campos estarão à disponibilidade de busca.

```<field name=_name_ type=_type_ indexed=_boolean_ stored=_boolean_ required=_boolean_ multiValued=_boolean_ />```

Seguindo esse exemplo criaremos um campo de nome DescriptorUI, do tipo string, indexado, guardado, necessário e simples:

```<field name="ScopeNote" type="string" indexed="true" stored="true" required="false" multiValued="false" />
```

Após fazer isso precisamos dar um Copyfield para adicionar esse field à busca, seguindo o exemplo a cima, simplesmente escreveremos a seguinte linha:

``` <copyField source="ScopeNote" dest="_text_"/>```

Após essa duas linha conseguimos adicionar o campo de ScopeNote na busca.

#### fieldType

O fieldType será usado quando se deseja melhorar a forma com que o texto é trabalhado, então no exemplo do ScopeNote declaramos o tipo como uma string, mas caso desejemos tokenizar as palavras, deixá-las em minúsculo, entre outros é preciso criar um tipo específico para isso.
```
<fieldType name="auto_text" class="solr.TextField" positionIncrementGap="100">
    <analyzer type="index">
            <tokenizer class="solr.KeywordTokenizerFactory" />
            <filter class="solr.LowerCaseFilterFactory" />
            <filter class="solr.PorterStemFilterFactory"/>
            <filter class="solr.StopFilterFactory" ignoreCase="true" words="stopwords.txt" />
            <!-- <filter class="solr.EdgeNGramFilterFactory" minGramSize="2" maxGramSize="15" /> -->
    </analyzer>
    <analyzer type="query">
            <tokenizer class="solr.KeywordTokenizerFactory" />
            <filter class="solr.LowerCaseFilterFactory" />
    </analyzer>
</fieldType>
```
Nesse exemplo criamos um tipo chamado auto_text, definimos então a classe dela como TextField, o qual tem funções de tokenização e minimização de palavras. No analyzer definimos a onde queremos aplicar as funções, seja no "index", texto a ser procurado, ou na "query", o que será procurado. Dentro do analyzer definimos o que queremos aplicar, no caso estamos aplicando uma tokenização e deixamos todas as letras em minúsculo, dessa forma podemos fazer buscas mais precisas em vez da busca por acerto exato.

Para aplicar esse novo tipo colocaremos seu nome no lugar do "type" quando declaramos a field, então para colocarmos esse novo tipo na ScopeNote basta fazer isso:

```
<field name="ScopeNote" type="auto_text" indexed="true" stored="true" required="false" multiValued="false" />

```
que essa field já aplicará o novo tipo que criamos, ainda  preciso dar um copyField para adicionarmos essa field à busca.

### Adicionando tudo ao solr

Com o banco de dados e o managed-schema prontos podemos adicioná-los ao solr.
Já iniciamos o solr com

```bin/solr start```

Já criamos o core com

```bin/solr create -c mesh -p 8983```

Já editamos o managed-schema no caminho dado por ```server/solr/mesh/conf```
Então deixamos nosso banco de dados em ```example/exampledocs```, como dito antes.
Disso tudo temos tudo pronto, para acessar o dicionário basta acessar esse link:
```http://localhost:8983/solr/mesh/select?q=*&wt=json```
Ele acessa a porta local 8983 do computador, a busca será dada pela variável "q" e o formato de retorno pela variável "wt"

### Busca

Como dito antes a busca será feita pela variável "q", então para se buscar um termo basta colocar ele depois do "q=", se a busca for um nome composto basta fazer isso ```q="nome composto"```, a sintaxe de ```q=*``` serve para listar os 10 primeiros termos. Caso se deseje especificar uma field em que se deseje procurar usamos a seguinte sintaxe ```q=ConceptName:("Myocardial%20Infarction")```

### O que está acontecendo por trás dos bastidores?

O Managed-schema é usado pelo solr, por conter a indicação dos fields que serão utilizados, para criar um index invertido, que nada mais é que uma forma de indexação de uma base de dados que mapeia e quebra  os elementos adicionados e salva em uma tabela, tornando se em algo muito eficiente para a realização de buscas, no nosso caso o solr está configurado também para remover as stop words da base de dados dada a ele e para fazer uma tokenização com stemming.

Os dados que passamos para o solr estão em arquivo XML com todos campos de interesse nosso, e junto com o campos os boosts opcionais para cada field, que permitem definir uma prioridade de resultado, no nosso caso apresentamos os seguintes pesos para boosts, e que podem ser editados na conversão do desc2020.xml para, no nosso caso, XMLsolr.xml:
-8.0 para DescriptorUI e ConceptName
-4.0 para EntryTerm e PreviousIndex
-2.0  para Annotation e ScopeNote

Com o index invertido construído já se pode fazer uma consulta no solr, que vai ser basicamente um requisição HTTP de URLs, o solr pega o que foi buscado e aplicará análises paralelas para os filtros até ter a construção de maior relevância de resultado, no nosso caso para haver uma priorização de certos campos, e passando por todo o processo, ele retorna os melhores resultados em forma de JSON


### Resumo

De forma rápida, caso já se tenha tudo pronto a lista de comandos será essa:

* Entramos no solr e vamos até o ```example/exampledocs```
* iniciar o solr:

```../../bin/solr start```

* caso já se tenha criado uma core antes é preciso deleta-la, para isso usamos esse comando:

```../../bin/solr delete -c mesh -p 8983```

* criar o mesh:

```../../bin/solr create -c mesh -p 8983```

* Editamos o managed-schema (se for fazer vários teste vale a pena copiar o managed-schema em uma pasta fora do mesh e depois só copiar ele de novo), no diretório ```server/solr/mesh/conf``` partindo do ```solr-8.3.0```

* Reiniciamos o mesh com:

```../../bin/solr restart```

* Adicionamos o banco de dados no solr(XMLsolr.xml é o nome do banco de dados obtido ao pegar os fields que seriam úteis do mesh):

```java -jar -Dc=mesh -jar post.jar XMLsolr.xml```

* Acessamos a porta local e verificamos se tudo foi adicionado com:

```http://localhost:8983/solr/mesh/select?q=*&wt=json```

* Fazemos uma busca como:

```http://localhost:8983/solr/mesh/select?q="Myocardial%20Infarction"&wt=json```

* Busca em um campo específico:

```http://localhost:8983/solr/mesh/select?q=ConceptName:("Myocardial%20Infarction")&wt=json```

Caso se deseje editar o managed-schema ou o banco de dados é preciso deletar o núcleo atual, no caso o mesh já criado, caso nãose faça isso pode-se ou gerar um erro ou adicionar novamente o banco de dados, deixando seu mesh com dois ou mais do mesmo termo
