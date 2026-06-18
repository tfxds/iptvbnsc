'///////////////////////////////////////////'
' Helper function convert AA array to Row Node
Function list2ContentNode(contentList as Object, parseFunc=stubFunc as Function, nodeType="ContentNode" as String, listLimit=contentList.count()) as Object
  result = createObject("roSGNode", nodeType)
  if result = invalid then result = createObject("roSGNode", "ContentNode")
  if isnonemptyArray(contentList)
    if listLimit > contentList.count() then listLimit = contentList.count()
    for i = 0 to listLimit - 1
      item = AAToNode(parseFunc(contentList[i]), nodeType)
      result.appendChild(item)
    end for
  end if
  return result
End Function

'///////////////////////////////////////////'
' Helper function convert AA to Node
Function ContentList2SimpleNode(contentList as Object, nodeType = "ContentNode" as String) as Object
  ''print "RegScreen.brs - [ContentList2SimpleNode]"
  result = createObject("roSGNode", nodeType)
  if result <> invalid
    for each itemAA in contentList
      item = createObject("roSGNode", nodeType)
      item.setFields(itemAA)
      result.appendChild(item)
    end for
  end if
  return result
End Function

'converts AA to ContentNode
Function aAToNode(inputAA = {} as Object, nodeType = "ContentNode" as String)
  item = createObject("roSGNode", nodeType)
  if item = invalid then item = createObject("roSGNode", "ContentNode")
  return appendAAToNode(inputAA, item)
End Function


Function nodeFieldsFilterAA()
  return  { focusedChild  : "focusedChild"
            change        : "change"
            metadata      : "metadata"
            nextPanelName : "nextPanelName"
            children      : "children"
          }
End Function


Function appendAAToNode(inputAA = {} as Object, item = invalid as Object)
  if item = invalid then item = createObject("roSGNode", "Node")
  existingFields = {}
  newFields = {}
    'AA of node read-only fields for filtering'
  fieldsFilterAA = nodeFieldsFilterAA()
  for each field in inputAA
    if item.hasField(field)
      if NOT fieldsFilterAA.doesExist(field) then existingFields[field] = inputAA[field]
    else
      newFields[field] = inputAA[field]
    end if
  end for
  item.setFields(existingFields)
  item.addFields(newFields)
  return item
End Function


Function nodeToAA(node)
  result = {}
  if node <> invalid
    nodeFields = node.getFields()
    'AA of node read-only fields for filtering'
    fieldsFilterAA = nodeFieldsFilterAA()
    for each field in nodeFields
      if NOT fieldsFilterAA.doesExist(field) then result[field] = nodeFields[field]
    end for
  end if
  return result
End Function


Function stubFunc(itemAA as Object) as Object
  return itemAA
End Function


Function findChildNode(node, value, field="id", recursive=false)
  for i = 0 to node.getChildCount() - 1
    if node.getChild(i)[field] = value then return node.getChild(i)
    if recursive and node.getChild(i).getChildCount() > 0
      item = findChildNode(node.getChild(i), value, field, recursive)
      if item <> invalid then return item
    end if
  end for
  return invalid
End Function


Function clearNodeAndCreateChild(topNode, nodeType, itemId=invalid)
  topNode.removeChildren(topNode.getChildren(-1, 0))
  item = topNode.createChild(nodeType)
  if itemId = invalid then itemId = nodeType
  item.id = itemId
  return item
End Function


sub setNodeFields(node, itemAA)
  appendAAToNode(itemAA, node)
end sub


sub setNodeField(node, key, value)
  if node.hasField(key)
    node[key] = value
  else
    fields = {}
    fields[key] = value
    node.addFields(fields)
  end if
end sub


sub setPosterMaxSize(poster, uri)
  if poster <> invalid and isnonemptystr(uri)
    poster.loadDisplayMode = "limitSize"
    di = CreateObject("roDeviceInfo")
    poster.loadWidth = di.GetUIResolution().width
    poster.loadHeight = di.GetUIResolution().height
    poster.uri = uri
    poster.width = di.GetUIResolution().width
    poster.height = di.GetUIResolution().height
  end if
end sub