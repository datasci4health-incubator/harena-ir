# harena-ir
Information Retrieval for Harena.

## Introdução
A recuperação de infromação é um tema amplamente estudado e utilizado na computação, nesse projeto em específico o objetivo é usar dessa ferramente para, através da entrada de conceitos relacionados à area da saúde, retornar a anotação que melhor se aplica ao termo dado, unsando o  MESH(Medical Subject Headings) e solr para isso.

## Guia
### Instalação do Solr
Instale em [solr.zip](http://ftp.unicamp.br/pub/apache/lucene/solr/8.3.1/solr-8.3.1.zip), e extraia-o

### Iniciando o solr
Para iniciar o solr precisamos estar dentro do diretorio "solr-8.3.0", dele digitamos

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

Com o core criado é necessário editar a "inteligencia" da busca, ela ficará localizada seguindo o seguinte caminho: ```server/solr/mesh/conf``` o nome do arquivo é ```managed-schema``` e será explicado em detalhes mais a frente. Neste arquivo declararemos os tipos de "fields" que serão usados nos textos, assim como seus formatos.

O banco de dados do mesh ficara no diretório ```example/exampledocs```.

### Banco de dados
Para adicionarmos novos dados ao nosso core precisamos deixar esses dados num formato xml especifico, para isso primeiramente pegaremos os dados do mesh.

#### Instalando o Mesh
O banco de dados do mesh que iremos usar estará no formato XML. Entrando no link a seguir faca o download no [desc2020.zip](https://github.com/Iwazo8700/mesh-annotation/blob/master/buid-solr/desc2020.zip), vale lmebrar que os dados do MESH são disponibilizados gratuitamente e possuem uma ampla documentação sobre sua estruura, para quem quiser conhecer mais a fundo

#### Edição do Mesh
Com a base instalada vamos editar esse xml para um xml que possa ser lido pelo solr e ser interpretado como informação, o jeito mais fácil que encontrei para fazer isso foi usando xpath e xquery.
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

Para tranformar o mesh em um xml válido usei o pragrama [parseXML2XMLsolr.xq](https://github.com/Iwazo8700/mesh-annotation/blob/master/buid-solr/parseXML2XMLsolr.xq), nele transformamos os seguintes dados em fields:
* DescriptorUI
* ConceptName
* ConceptUI
* EntryTerm
* PreviousIndexing
* Annotation
* ScopeNote
* DateCreated
#### Xpath e Xquery(parseXML2XMLsolr.xq)
A lógica usada para fazer esse programa foi usando caminhos que cheguem aonde quero aplicando a / para passar de uma camada para outra até chegar no termo desejado ou quando existia um termo unico usava a // para ir direto ao ponto. O xquery usei no momento e que se tinha um termo que desejava inserir, mas ele não era simples e precisava pegar esse termo várias vezes, para isso usei o conseito de for do xquery. Tudo que precisei fazer nesse ponto foi codificado na xbase, um editor especializado nesse tipo de situação.

```let $mesh := doc("/home/enzo/Documentos/Docker/desc2020.xml")

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

Nesse trecho por exemplo, defini o caminho do desc2020.xml em $mesh, printei o \<add\>, criei um for que passa por cada DescriptorRecord do arquivo, dentro de cada DescriptorRecord printei um \<doc\>, um \<field name="ScopeNote" boost="2.0"\>, o texto do ScopeNote desse DescriptorRecord e fechei o field com \<\\field\>, finalizando esse doc com o <\doc>. Depois de passar por todos DescriptorRecord, finalizo o documento com o \<\\add\>, adquirindo um documento que começa com <add>, termina com \<\\add\>, e dentro desse add vários \<doc\> e \<\\doc\>, cada um com seu ScopeNote. Lembrando que o boost é opcional e só será usado para definir uma prioridade de field na hora da busca.


### Managed-Schema
#### Field
Nesse arquivo temos varios tipos de classes a serem declaradas, mas para criarmos um campo de busca focamos na classe \<field\>, nela iremos declarar quais tipos de campos estarão à disponibilidade de busca.

```<field name=_name_ type=_type_ indexed=_boolean_ stored=_boolean_ required=_boolean_ multiValued=_boolean_ />```

Seguindo esse exemplo criaremos um campo de nome DescriptorUI, do tipo string, indexado, guardado, necassário e simples:

```<field name="ScopeNote" type="string" indexed="true" stored="true" required="false" multiValued="false" />
```

Após fazer isso precisamos dar um Copyfield para adicionar esse field à busca, seguindo o explo a cima, simplesmente escreveriamos a seguinte linha:

``` <copyField source="ScopeNote" dest="_text_"/>```

Após essa duas linha conseguimos adicionar o campo de ScopeNote na busca.

#### fieldType

O fieldType será usado quando se deseja melhorar a forma com que o texto é trabalhado, então no exemplo do ScopeNote declaramos o tipo como uma string, mas caso desejemos tokenizar as palavras, deixá-las em minisculo, entre outros é preciso criar um tipo especifico para isso.
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
Nesse exmplo criamos um tipo chamado auto_text, definimos entao a classe dela como TextField, o qual tem funções de tokenização e minimização de palavras. No analyzer definimos aonde queremos aplicar as funções, seja no "index", texto a ser procurado, ou na "query", o que será procurado. Dentro do analyzer definimos o que queremos aplicar, no caso estamos aplicando uma tokenização e deixamos todas as letras em minusculo, dessa forma podemos fazer buscas mais precisas em vez da busca por acerto exato.

Para aplicar esse novo tipo colocaremos seu nome no lugar do "type" quando declaramos a field, então para colocarmos esse novo tipo na ScopeNote basta fazer isso:

```
<field name="ScopeNote" type="auto_text" indexed="true" stored="true" required="false" multiValued="false" />

```
que essa field já aplicará o novo tipo que criamos, ainda  preciso dar um copyField para adicionarmos essa field à busca.

### Adicionando tudo ao solr

Com o banco de dados e o managed-schema prontos podemos adicioná-los ao solr.
Ja iniciamos o solr com

```bin/solr start```

Ja criamos o core com

```bin/solr create -c mesh -p 8983```

Ja editamos o managed-schema no caminho dado por ```server/solr/mesh/conf```
Então deixamos nosso banco de dados em ```example/exampledocs```, como dito antes.
Disso tudo temos tudo pronto, para acessar o dicionário basta acessar esse link:
```http://localhost:8983/solr/mesh/select?q=*&wt=json```
Ele acessa a porta local 8983 do comútador, a busca será dada pela variável "q" e o formato de retorno pela variável "wt"

### Busca

Como dito antes a busca será feita pela variàvel "q", então para se buscar um termo basta colocar ele deopis do "q=", se a busca for um nome composto basta fazer isso ```q="nome composto"```, a sintaxe de ```q=*``` serve para listar os 10 primeiros termos. Caso se deseje especificar uma field em que se deseje procurar usamos a seguinte sintaxe ```q=ConceptName:("Myocardial%20Infarction")```

### O que está acontecendo por trás dos bastidores?

O Managed-schema é usado pelo solr, por conter a indicação dos fields que serão utilizados, para criar um index invertido, que nada mais é que uma forma de indexação de uma base de dados que mapeia e quebra  os elementos adicionados e salva em uma tabela, tornando se em algo muito eficiente para a realização de buscas, no nosso caso o solr está configurado também para remover as stop words da base de dados dada a ele e para fazer uma tokenização com stemming.

Com o index invertido construido já se pode fazer uma consulta no solr, que vai ser basicamente um requisição HTTP de URLs, o solr pega o que foi buscado e aplica analises paralelas para os filtros até ter a construção de maior relevância de resultado, no nosso caso para haver uma priorização de certos campos, e passando por todo o processo, ele retorna os melhores resultados em forma de JSON


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

* Adicionamos o banco de dados no solr(XMLsolr.xml é o nome do meu banco de dados editado):

```java -jar -Dc=mesh -Dauto example/exampledocs/post.jar desc2020.xml```

* Acessamos a porta local e verificamos se tudo foi adicionado com:

```http://localhost:8983/solr/mesh/select?q=*&wt=json```

* Fazemos uma busca como:

```http://localhost:8983/solr/mesh/select?q="Myocardial%20Infarction"&wt=json```

* Busca em um campo especifico:

```http://localhost:8983/solr/mesh/select?q=ConceptName:("Myocardial%20Infarction")&wt=json```

Caso se deseje editar o managed-schema ou o banco de dados é preciso deletar o núcleo atual, no caso o mesh já criado, caso nãose faça isso pode-se ou gerar um erro ou adicionar novamente o banco de dados, deixando seu mesh com dois ou ais do mesmo termo
