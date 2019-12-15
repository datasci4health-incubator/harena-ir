let $mesh := doc("/home/enzo/Documentos/Docker/desc2020.xml")

return
<add>
{
  for $d in ($mesh//DescriptorRecord)
  return
  <doc>
     <field name="DescriptorUI">{$d/DescriptorUI/text()}</field>
     {
       for $cn in ($d//ConceptName)
       return
       <field name="ConceptName" boost="8.0">{$cn/String/text()}</field>
     }
     
     {
       for $c in ($d//ConceptUI)
       return
       <field name="ConceptUI">{$c/text()}</field>
     }
     
     {
       for $tl in ($d//TermList/Term)
         return
         <field name="EntryTerm" boost="4.0">{$tl//String/text()}</field>
     }
     
     {
       for $pi in ($d//PreviousIndexing)
       return
       <field name="PreviousIndexing" boost="4.0">{$pi/text()}</field>
     }
     
     <field name="Annotation" boost="2.0">{$d//Annotation/text()}</field>
     
     <field name="ScopeNote" boost="2.0">{$d//ScopeNote/text()}</field>
     <field name="DateCreated">{$d/DateCreated/Year/text()}-{$d/DateCreated/Month/text()}-{$d/DateCreated/Day/text()}</field>
     
  </doc>
}
</add>