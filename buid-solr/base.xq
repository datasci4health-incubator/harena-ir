let $mesh := doc("/home/enzo/Documentos/Docker/bar.xml")

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
       <field name="ConceptName" >{$cn/String/text()}</field>
     }
     
     {
       for $c in ($d//ConceptUI)
       return
       <field name="ConceptUI">{$c/text()}</field>
     }
     
     {
       for $tl in ($d//TermList/Term)
         return
         <field name="EntryTerm" >{$tl//String/text()}</field>
     }
     
     {
       for $pi in ($d//PreviousIndexing)
       return
       <field name="PreviousIndexing" >{$pi/text()}</field>
     }
     
     <field name="Annotation">{$d//Annotation/text()}</field>
     
     <field name="ScopeNote">{$d//ScopeNote/text()}</field>
     <field name="DateCreated">{$d/DateCreated/Year/text()}-{$d/DateCreated/Month/text()}-{$d/DateCreated/Day/text()}</field>
     
  </doc>
}
</add>