#!/usr/bin/python3
#Author: Alexandre Halbardier & Martin Meerts

import json
import argparse
import sys
import subprocess

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Flattener for solidity files
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"""
Functions corresponding to a nodeType
"""

def sourceUnit(jsonFile):

    license = "// SPDX-License-Identifier: " + jsonFile["license"] + "\n\n" if "license" in jsonFile.keys() and not jsonFile["license"] is None else ""
    return license

def pragmaDirective(jsonFile):

    version = jsonFile["literals"][0]

    if version == "solidity":
        for i in range(1,len(jsonFile["literals"]),3):
            version += " "
            for j in range (0,3):
                if i+j < len(jsonFile["literals"]):
                    version += jsonFile["literals"][i+j]

    if version == "experimental":
        version += " " + jsonFile["literals"][1]
        
    if version == "abicoder":
        version += " " + jsonFile["literals"][1]

    pragmaVersion = "pragma "+ version+ ";\n\n"
    return pragmaVersion

def contractDefinition(jsonFile):

    documentation = jsonFile["documentation"] if "documentation" in jsonFile.keys() else None
    documentation = documentation if type(documentation)== str else (getNodeType(documentation) if type(documentation)== dict else None)  #for solidity before 6
    documentation = "/**\n* " + documentation.replace("\n","\n* ") + "\n*/\n" if not documentation is None else ""
    abstract =  "abstract " if "abstract" in jsonFile.keys() and jsonFile["abstract"] else ""
    contractKind = jsonFile["contractKind"] + " "
    name = jsonFile["name"] + " "
    listInheritedContracts = "is " + commaBetweenElements(jsonFile["baseContracts"]) if commaBetweenElements(jsonFile["baseContracts"]) != "" else ""
    usingForDirective = variableDeclaration = eventDefinition = modifierDefinition = structDefinition = functionDefinition = ""
    listNodes = ""

    for elem in jsonFile["nodes"]:
        listNodes += "    " + getNodeType(elem)

    listNodes= " {\n" + listNodes + "}\n\n\n"
    return documentation + abstract + contractKind + name + listInheritedContracts + listNodes

def inheritanceSpecifier(jsonFile):
    
    baseName = getNodeType(jsonFile["baseName"])
    arguments = "(" + commaBetweenElements(jsonFile["arguments"]) + ")" if "arguments" in jsonFile.keys() and jsonFile["arguments"] is not None else ""
    return baseName + arguments

def functionDefinition(jsonFile):

    documentation = jsonFile["documentation"] if "documentation" in jsonFile.keys() else None
    documentation = documentation if type(documentation)== str else (getNodeType(documentation) if type(documentation)== dict else None)  #for solidity before 6
    documentation = "/**\n        * " + documentation.replace("\n","\n        * ") + "\n        */\n        " if not documentation is None else ""
    kind = jsonFile["kind"] + " "
    name = jsonFile["name"] + " "
    parameters = getNodeType(jsonFile["parameters"]) +  " "
    listModifiers = ""
    visibility = jsonFile["visibility"] + " "
    stateMutability = jsonFile["stateMutability"] + " " if jsonFile["stateMutability"] in ("mutable","view","payable","pure") else ""
    virtual = "virtual " if "virtual" in jsonFile.keys() and jsonFile["virtual"] == True else ""
    overrides= "override " + getNodeType(jsonFile["overrides"]) + " " if "overrides" in jsonFile.keys() and jsonFile["overrides"] is not None else ""
    returnParameters = "returns " + getNodeType(jsonFile["returnParameters"]) if not getNodeType(jsonFile["returnParameters"]) == "()" else ""
    body = " " + getNodeType(jsonFile["body"]) +"\n\n" if jsonFile["implemented"] == True else (";\n" if len(parameters)+len(returnParameters) <79 else ";\n\n" )

    for elem in jsonFile["modifiers"]:
        listModifiers+=getNodeType(elem) + " "
        
    return  (documentation + kind + name + parameters + listModifiers + visibility + stateMutability +  virtual + overrides +returnParameters).replace("  "," ") + body

def parameterlist(jsonFile):

    listParameters = "(" + commaBetweenElements(jsonFile["parameters"]) + ")"
    return listParameters

def modifierInvocation(jsonFile):

    listModifierName = getNodeType(jsonFile["modifierName"])
    listArguments = "(" + commaBetweenElements(jsonFile["arguments"]) + ")" if "arguments" in jsonFile.keys() and jsonFile["arguments"] is not None else ""
    return listModifierName + listArguments

def block(jsonFile):

    listStatements = ""

    for elem in jsonFile["statements"]:
        listStatements += "        " + getNodeType(elem) + "\n"

    listStatements = "{\n" + listStatements + "    }"
    return listStatements

def variableDeclarationStatement(jsonFile):

    listDeclarations = commaBetweenElements(jsonFile["declarations"])
    initialValue = (" = " + getNodeType(jsonFile["initialValue"]) if "initialValue" in jsonFile.keys() and not jsonFile["initialValue"] is None else "") + ";"

    if len(jsonFile["declarations"])>1:
        listDeclarations = "(" + listDeclarations + ")"

    return listDeclarations + initialValue

def returnStatement(jsonFile):

    expression = "return " + (getNodeType(jsonFile["expression"]) if "expression" in jsonFile.keys() and jsonFile["expression"] is not None else "")  + ";"
    return expression

def functionCall(jsonFile):

    expression = getNodeType(jsonFile["expression"]) if "expression" in jsonFile.keys() and jsonFile["expression"] is not None else ""
    listArguments = "(" + commaBetweenElements(jsonFile["arguments"]) + ")"

    if jsonFile["kind"] == "typeConversion":
        for elem in ["mutable","view","payable","pure"]:
            if elem in expression:
                expression = elem
                
    if jsonFile["kind"]=="structConstructorCall":
        args = ""
        for i in range(0,len(jsonFile["arguments"])):
            args += (jsonFile["names"][i] + ": " if len(jsonFile["names"])!=0 else "") + getNodeType(jsonFile["arguments"][i]) + (",\n        " if i < len(jsonFile["arguments"])-1 else "")
            listArguments = ("({\n        " + args +  "\n        })") if len(jsonFile["names"])!=0 else  ("(\n        " + args +  "\n        )")

    return expression + listArguments
    
def identifier(jsonFile):
    
    name = jsonFile["name"]
    return name

def variableDeclaration(jsonFile):

    documentation = jsonFile["documentation"] if "documentation" in jsonFile.keys() else None
    documentation = documentation if type(documentation)== str else (getNodeType(documentation) if type(documentation)== dict else None)  #for solidity before 6
    documentation = "/**\n        * " + documentation.replace("\n","\n        * ") + "\n        */\n        " if not documentation is None else ""
    typeName = getNodeType(jsonFile["typeName"])
    constant = " constant" if jsonFile["constant"] else ""
    indexed = " indexed" if "indexed" in jsonFile.keys() and jsonFile["indexed"] else ""
    immutable = " immutable" if "mutability" in jsonFile.keys() and (not jsonFile["mutability"] or jsonFile["mutability"]=="immutable") else ""
    storageLocation = " " + jsonFile["storageLocation"] if not jsonFile["storageLocation"] == "default" else ""
    override = " override " + getNodeType(jsonFile["overrides"]) + " " if "overrides" in jsonFile.keys() and jsonFile["overrides"] is not None else ""
    visibility = " " + jsonFile["visibility"] if jsonFile["stateVariable"] ==True else ""
    name = " " + jsonFile["name"] if not jsonFile["name"] == "" else ""
    value = " = " + getNodeType(jsonFile["value"]) if "value" in jsonFile.keys() and jsonFile["value"] is not None else ""
    variableDeclaration = documentation + typeName + constant + indexed + immutable + storageLocation + override + visibility + name + value
    variableDeclaration = variableDeclaration[:-1] if (variableDeclaration == typeName and variableDeclaration[-1]==" ") else variableDeclaration

    return (variableDeclaration + (";\n" if jsonFile["stateVariable"] ==True else "")).replace("  "," ")

def literal(jsonFile):

    constant = "constant" if jsonFile["isConstant"]==True else ""
    value = jsonFile["value"] if "value" in jsonFile.keys() and jsonFile["value"] is not None else ("hex\""+jsonFile["hexValue"]+"\"")
    value = "hex\""+jsonFile["hexValue"]+"\"" if jsonFile["kind"]=="hexString" else value

    if "\\" in value:
        value = value.replace("\\","\\\\")

    if "\u0019" in value:
        value = value.replace("\u0019","\\x19")
    if "\u0001" in value:
        value = value.replace("\u0001","\\x01")

    value = value.replace("\a","\\a").replace("\r","\\r").replace("\t","\\t").replace("\f","\\f").replace("\v","\\v").replace("\b","\\b").replace("\n","\\n")
    value = value if jsonFile["kind"]!="string" else ("\"" + value + "\"" if "value" in jsonFile.keys() and jsonFile["value"] is not None else value)
    subdenomination = " " + jsonFile["subdenomination"] if "subdenomination" in jsonFile.keys() and jsonFile["subdenomination"] is not None else ""
    return constant + value + subdenomination

def modifierDefinition(jsonFile):

    documentation = jsonFile["documentation"] if "documentation" in jsonFile.keys() else None
    documentation = documentation if type(documentation)== str else (getNodeType(documentation) if type(documentation)== dict else None)  #for solidity before 6
    documentation = "    /**\n        * " + documentation.replace("\n","\n        * ") + "\n        */\n        " if not documentation is None else ""
    name = "modifier " + jsonFile["name"] + " "
    virtual = "virtual " if "virtual" in jsonFile.keys() and jsonFile["virtual"] == True else ""
    overrides= "override " + getNodeType(jsonFile["overrides"]) + " " if "overrides" in jsonFile.keys() and jsonFile["overrides"] is not None else ""
    listParameters = getNodeType(jsonFile["parameters"])
    body = getNodeType(jsonFile["body"])+ "\n\n"
    return documentation + name + listParameters + overrides + virtual + body

def expressionStatement(jsonFile):

    expression = getNodeType(jsonFile["expression"]) + ";"
    return expression

def binaryOperation(jsonFile):

    leftExpression = getNodeType(jsonFile["leftExpression"]) + " "
    operator = jsonFile["operator"] + " "
    rightExpression = getNodeType(jsonFile["rightExpression"])
    return leftExpression + operator + rightExpression

def overrideSpecifier(jsonFile):

    overrides = "(" + commaBetweenElements(jsonFile["overrides"]) + ")" if jsonFile["overrides"]!=[] else ""
    return overrides

def userDefinedTypeName(jsonFile):
    
    name = jsonFile["name"] if "name" in jsonFile.keys() else getNodeType(jsonFile["pathNode"])
    return name

def elementaryTypeName(jsonFile):

    name = jsonFile["name"] + " "
    stateMutability = jsonFile["stateMutability"] if "stateMutability" in jsonFile.keys() and (jsonFile["stateMutability"] in ("mutable","view","payable","pure")) else ""
    return name + stateMutability

def placeholderStatement(jsonFile):

    return "_;"

def assignment(jsonFile):

    leftHandSide = getNodeType(jsonFile["leftHandSide"]) + " "
    operator = jsonFile["operator"] + " "
    rightHandSide = getNodeType(jsonFile["rightHandSide"])
    return leftHandSide + operator + rightHandSide

def memberAccess(jsonFile):

    expression = getNodeType(jsonFile["expression"]) + "."
    memberName = jsonFile["memberName"]
    return expression + memberName

def arrayTypeName(jsonFile):

    baseType = getNodeType(jsonFile["baseType"])
    length = "["+ ("" if (not "length" in jsonFile.keys() or jsonFile["length"] is None) else (jsonFile["length"] if type(jsonFile["length"])==str else getNodeType(jsonFile["length"]))) + "]"
    return  baseType + length

def structuredDocumentation(jsonFile):

    text = jsonFile["text"]
    return text

def inlineAssembly(jsonFile):

    inlineAssembly = "assembly " + (getNodeType(jsonFile["AST"]) if "AST" in jsonFile.keys() else jsonFile["operations"])

    if inlineAssembly[-1] == "}":
        inlineAssembly= inlineAssembly[:-1] + "    }"

    return inlineAssembly

def yulBlock(jsonFile):

    listStatements = ""

    for elem in jsonFile["statements"]:
        listStatements += "\n            " + getNodeType(elem)

    listStatements = "{" + listStatements + "\n        }"
    return listStatements

def yulAssignment(jsonFile):

    variableNames = commaBetweenElements(jsonFile["variableNames"])
    value = " := " + (getNodeType(jsonFile["value"]) if "value" in jsonFile.keys() and jsonFile["value"] is not None else "")
    return variableNames + value

def yulIdentifier(jsonFile):

    name = jsonFile["name"]
    return name

def yulFunctionCall(jsonFile):

    functionName = getNodeType(jsonFile["functionName"])
    listArguments = "(" + commaBetweenElements(jsonFile["arguments"]) + ")"
    return functionName + listArguments

def yulVariableDeclaration(jsonFile):

    variables = "let " + commaBetweenElements(jsonFile["variables"])
    value = " := " + getNodeType(jsonFile["value"])
    return variables + value

def yulTypedName(jsonFile):

    name = jsonFile["name"]
    return name

def yulExpressionStatement(jsonFile):

    expression = getNodeType(jsonFile["expression"])
    return expression

def yulLiteral(jsonFile):

    value = ("\"" + jsonFile["value"] + "\"" if jsonFile["kind"]=="string" else jsonFile["value"])
    return value

def yulSwitch(jsonFile):

    expression = "switch " + getNodeType(jsonFile["expression"]) + "\n            "
    cases = ""

    for elem in jsonFile["cases"]:
        cases += getNodeType(elem)

    return expression + cases

def yulCase(jsonFile):

    value = ("default " if jsonFile["value"] == "default" else "case " + getNodeType(jsonFile["value"]))
    body = getNodeType(jsonFile["body"])
    return value + body

def yulIf(jsonFile):

    condition = "if " + getNodeType(jsonFile["condition"])
    body = getNodeType(jsonFile["body"])

    if body[-1] == "}":
        body= body[:-1] + "    }"

    return  condition + body

def yulForLoop(jsonFile):

    pre = "for " + getNodeType(jsonFile["pre"])
    condition = " " + getNodeType(jsonFile["condition"])
    post = " " + getNodeType(jsonFile["post"])
    body = " " + getNodeType(jsonFile["body"])

    if pre[-1] == "}":
        pre = pre[:-1] + "    }"
    if post[-1] == "}":
        post = post[:-1] + "    }"
    if body[-1] == "}":
        body = body[:-1] + "    }"

    return pre + condition + post + body

def yulFunctionDefinition(jsonFile):

    name = "function " + jsonFile["name"]
    parameters = "(" + commaBetweenElements(jsonFile["parameters"]) + ") " if "parameters" in jsonFile.keys() else "() "
    returnVariables = "-> " + commaBetweenElements(jsonFile["returnVariables"]) + " " if "returnVariables" in jsonFile.keys() else ""
    body = getNodeType(jsonFile["body"])

    if body[-1] == "}":
        body = body[:-1] + "    }"

    return name + parameters + returnVariables + body

def elementaryTypeNameExpression(jsonFile):

    typeName = jsonFile["typeName"] if type(jsonFile["typeName"])==str else getNodeType(jsonFile["typeName"])
    return typeName

def functionCallOptions(jsonFile):

    expression = getNodeType(jsonFile["expression"])
    namesOptions = ""

    for i in range(0,len(jsonFile["options"])):
        namesOptions += (jsonFile["names"][i] + ": " if len(jsonFile["names"])!=0 else "") + getNodeType(jsonFile["options"][i]) + ("," if i < len(jsonFile["options"])-1 else "")

    namesOptions = "{" + namesOptions + "}"
    return expression + namesOptions

def ifStatement(jsonFile):

    condition = "if (" + getNodeType(jsonFile["condition"]) + ")"
    trueBody = getNodeType(jsonFile["trueBody"])
    falseBody = ("\n        else " + getNodeType(jsonFile["falseBody"])) if "falseBody" in jsonFile.keys() and jsonFile["falseBody"] is not None else ""

    if trueBody[-1] == "}":
        trueBody = trueBody[:-1] + "    }"
    if len(falseBody)>0 and falseBody[-1] == "}":
        falseBody = falseBody[:-1] + "    }"

    return  condition + trueBody + falseBody

def structDefinition(jsonFile):

    name = "struct " + jsonFile["name"]
    members =""
    
    for elem in jsonFile["members"]:
        members += "    "+getNodeType(elem) + ";\n"

    members = " {\n" + members + "    }\n\n"
    return name + members

def mapping(jsonFile):

    keyType = "mapping ("+getNodeType(jsonFile["keyType"]) + "=>"
    valueType = getNodeType(jsonFile["valueType"]) + ")"
    return keyType + valueType

def unaryOperation(jsonFile):

    operator= jsonFile["operator"] + " "
    subExpression = getNodeType(jsonFile["subExpression"])
    return (operator + subExpression) if jsonFile["prefix"] == True else subExpression + operator

def indexAccess(jsonFile):

    baseExpression = getNodeType(jsonFile["baseExpression"])
    indexExpression = "[" + (getNodeType(jsonFile["indexExpression"]) if "indexExpression" in jsonFile.keys() and jsonFile["indexExpression"] is not None else "")  + "]"
    return baseExpression + indexExpression

def eventDefinition(jsonFile):

    documentation = jsonFile["documentation"] if "documentation" in jsonFile.keys() else None
    documentation = documentation if type(documentation)== str else (getNodeType(documentation) if type(documentation)== dict else None)  #for solidity before 6
    documentation = "    /**\n        * " + documentation.replace("\n","\n        * ") + "\n        */\n        " if not documentation is None else ""
    name = "event " + jsonFile["name"]
    parameters = getNodeType(jsonFile["parameters"])
    anonymous = " anonymous;\n" if "anonymous" in jsonFile.keys() and jsonFile["anonymous"] else ";\n"
    return documentation + name + parameters + anonymous

def emitStatement(jsonFile):

    eventCall = "emit " + getNodeType(jsonFile["eventCall"]) + ";"
    return eventCall

def usingForDirective(jsonFile):

    libraryName = "using " + getNodeType(jsonFile["libraryName"]) + " for "
    typeName = (getNodeType(jsonFile["typeName"]) if "typeName" in jsonFile.keys() and jsonFile["typeName"] is not None else "*") + ";\n"
    return libraryName + typeName

def forStatement(jsonFile):
    
    initializationExpression = "for (" + (getNodeType(jsonFile["initializationExpression"]) if "initializationExpression" in jsonFile.keys() and jsonFile["initializationExpression"] is not None else ";") + " "
    condition = (getNodeType(jsonFile["condition"]) if "condition" in jsonFile.keys() and jsonFile["condition"] is not None else "") + "; "
    loopExpression = (getNodeType(jsonFile["loopExpression"]).replace(";","") if "loopExpression" in jsonFile.keys() and jsonFile["loopExpression"] is not None else "") +") "
    body = getNodeType(jsonFile["body"])
    return initializationExpression + condition + loopExpression + body

def tupleExpression(jsonFile):

    components = commaBetweenElements(jsonFile["components"])
    components = "[" + components + "]" if jsonFile["isInlineArray"] else "(" + components + ")"
    return components

def newExpression(jsonFile):

    typeName = "new " + getNodeType(jsonFile["typeName"])
    return typeName

def typeBreak(jsonFile):

    return "break;\n"

def conditional(jsonFile):

    condition = getNodeType(jsonFile["condition"]) + " ? "
    trueExpression = getNodeType(jsonFile["trueExpression"]) + " : "
    falseExpression = getNodeType(jsonFile["falseExpression"])
    return condition + trueExpression + falseExpression

def enumDefinition(jsonFile):

    name = "enum " + jsonFile["name"] + " "
    members = "{" + commaBetweenElements(jsonFile["members"]) + "}\n\n"
    return name + members

def enumValue(jsonFile):

    name = jsonFile["name"]
    return name

def whileStatement(jsonFile):

    condition = "while (" + getNodeType(jsonFile["condition"]) + ") "
    body = getNodeType(jsonFile["body"])

    if body[-1] == "}":
        body = body[:-1] + "    }"

    return condition + body

def continueStatement(jsonFile):

    return "continue;"

def tryStatement(jsonFile):

    externalCall = "try \n        " + getNodeType(jsonFile["externalCall"])
    clauses = ""
    for i in range(0,len(jsonFile["clauses"])):
        if i == 0 and "catch" in getNodeType(jsonFile["clauses"][i]):
            clauses += getNodeType(jsonFile["clauses"][i]).replace("catch","")
        elif i != 0 and "returns" in getNodeType(jsonFile["clauses"][i]):
            clauses += getNodeType(jsonFile["clauses"][i]).replace("returns","catch")
        else:
            clauses += getNodeType(jsonFile["clauses"][i])
        if clauses[-1] == "}":
            clauses = clauses[:-1] + "    }"

    return externalCall + clauses

def tryCatchClause(jsonFile):

    errorName = jsonFile["errorName"] + " " if "errorName" in jsonFile.keys() and jsonFile["errorName"] is not None else ""
    parameters = getNodeType(jsonFile["parameters"]) if "parameters" in jsonFile.keys() and jsonFile["parameters"] is not None else ""
    block = getNodeType(jsonFile["block"])

    return "\n        " + ("returns " + errorName + parameters + block if parameters != "" else ("catch" + errorName + block))

def doWhileStatement(jsonFile):

    body = "do " + getNodeType(jsonFile["body"])

    if body[-1] == "}":
            body = body[:-1] + "    }"

    condition = " while (" + getNodeType(jsonFile["condition"]) + ");"
    return body + condition

def identifierPath(jsonFile):

    name = jsonFile["name"]
    return name

def uncheckedBlock(jsonFile):

    listStatements = ""

    for elem in jsonFile["statements"]:
        listStatements += "        " + getNodeType(elem) + "\n"
        
    listStatements = "unchecked {\n" + listStatements + "    }"
    return listStatements

def indexRangeAccess(jsonFile):

    baseExpression = getNodeType(jsonFile["baseExpression"])
    startExpression = "[" + (getNodeType(jsonFile["startExpression"]) if jsonFile["startExpression"] is not None else "") + ":"
    endExpression = (getNodeType(jsonFile["endExpression"]) if jsonFile["endExpression"] is not None else "") + "]"

    return baseExpression + startExpression + endExpression

def getNodeType(jsonFile):

    if (not "nodeType" in jsonFile.keys()):
        print("the nodeType key doesn't exist")

    else :
        nodeType = jsonFile["nodeType"]
        switcher = {
        "SourceUnit": sourceUnit,
        "PragmaDirective" : pragmaDirective,
        "ContractDefinition" : contractDefinition,
        "InheritanceSpecifier" : inheritanceSpecifier,
        "FunctionDefinition" : functionDefinition,
        "Block": block,
        "ParameterList": parameterlist,
        "VariableDeclarationStatement":variableDeclarationStatement,
        "FunctionCall": functionCall,
        "VariableDeclaration": variableDeclaration,
        "Identifier": identifier,
        "ModifierInvocation": modifierInvocation,
        "Literal": literal,
        "ModifierDefinition": modifierDefinition,
        "Return": returnStatement,
        "ExpressionStatement": expressionStatement,
        "BinaryOperation": binaryOperation,
        "OverrideSpecifier" : overrideSpecifier,
        "UserDefinedTypeName" : userDefinedTypeName,
        "ElementaryTypeName" : elementaryTypeName,
        "PlaceholderStatement" : placeholderStatement,
        "Assignment" : assignment,
        "MemberAccess" : memberAccess,
        "ArrayTypeName" : arrayTypeName,
        "StructuredDocumentation": structuredDocumentation,
        "InlineAssembly":inlineAssembly,
        "ElementaryTypeNameExpression" : elementaryTypeNameExpression,
        "FunctionCallOptions" : functionCallOptions,
        "IfStatement":ifStatement,
        "YulBlock" : yulBlock,
        "YulAssignment" : yulAssignment,
        "YulIdentifier" : yulIdentifier,
        "YulFunctionCall" : yulFunctionCall,
        "YulVariableDeclaration" : yulVariableDeclaration,
        "YulTypedName" : yulTypedName,
        "YulExpressionStatement": yulExpressionStatement,
        "YulLiteral" : yulLiteral,
        "YulSwitch" : yulSwitch,
        "YulCase" : yulCase,
        "YulIf" : yulIf,
        "YulForLoop" : yulForLoop,
        "YulFunctionDefinition" : yulFunctionDefinition,
        "StructDefinition" : structDefinition,
        "Mapping" : mapping,
        "UnaryOperation" : unaryOperation,
        "IndexAccess" : indexAccess,
        "EventDefinition" : eventDefinition,
        "EmitStatement" : emitStatement,
        "UsingForDirective" : usingForDirective,
        "ForStatement" : forStatement,
        "TupleExpression" : tupleExpression,
        "NewExpression" : newExpression,
        "Break" : typeBreak,
        "Conditional" : conditional,
        "EnumDefinition" : enumDefinition,
        "EnumValue" : enumValue,
        "WhileStatement" : whileStatement,
        "Continue" : continueStatement,
        "TryStatement" : tryStatement,
        "TryCatchClause" : tryCatchClause,
        "DoWhileStatement" : doWhileStatement,
        "IdentifierPath" : identifierPath,
        "UncheckedBlock" : uncheckedBlock,
        "IndexRangeAccess" : indexRangeAccess
        #ImportDirect is handled by orderToImport function
        }
        func = switcher.get(nodeType)
           
    if (func is None):
        print("!!!!!\n")
        print("!!!!!\n")
        print("Flattener Error for type: " + nodeType)
        print("!!!!!\n")
        print("!!!!!\n")

    else:
        return func(jsonFile)
    
"""
Functions to help the writing
"""

def splitAstElements(astToSplit):
    newlist = []
    totalBraces = 0
    
    for i in range(0, len(astToSplit)):
        line = astToSplit[i]
        lineBraces = line.count("{") - line.count("}")
        if (lineBraces > 0 and totalBraces ==0):
            newlist.append(line)
        if (totalBraces > 0):
            newlist[-1] += line
        totalBraces+=lineBraces

    for i in range(0, len(newlist)):
        newlist[i]= json.loads(newlist[i])

    return newlist

def commaBetweenElements(jsonFile):

    elements=""

    if jsonFile is not None:
        for i in range(0,len(jsonFile)):
            elements += getNodeType(jsonFile[i]) if jsonFile[i] is not None else ""
            if i < len(jsonFile)-1:
                elements+= ", "
    
    if len(elements)>79:
        elements = ""
        if jsonFile is not None:
            for i in range(0,len(jsonFile)):
                elements += "\n                " + getNodeType(jsonFile[i]) if jsonFile[i] is not None else ""
                if i < len(jsonFile)-1:
                    elements+= ","
                else:
                    elements+= "\n"+"        "
                
    return elements

def orderToImport(absolutePath,listFiles):

    importedContracts = [absolutePath]

    for jsonFile in listFiles:
        if absolutePath == jsonFile["absolutePath"]:
            for elem in jsonFile["nodes"]:
                if elem["nodeType"]=="ImportDirective":
                    importedContracts = orderToImport(elem["absolutePath"],listFiles) + importedContracts
                    
    return list(dict.fromkeys(importedContracts)) #delete duplicates

def generateFile(order, listFiles):

    nodes = ""

    for i in range(0,len(order)):
        for elem in listFiles:
            if elem["absolutePath"] ==  order[i]:
                if i==0 and elem["nodeType"]=="SourceUnit":
                    nodes += sourceUnit(elem)
                for node in elem["nodes"]:
                    if node["nodeType"] != "ImportDirective":
                        nodes += getNodeType(node)
    
    if "pragma solidity ^0.5" in nodes or "pragma solidity 0.5" in nodes or "pragma solidity >=0.5" in nodes:
        nodes = nodes.replace("fallback","function")
        
    return nodes 

def flatten(contract):
    
    arguments = ["solc", "--ast-compact-json", contract]
    proc = subprocess.run(arguments,stdout=subprocess.PIPE, universal_newlines=True)
    name = contract.split("/")[-1]
    
    if(proc.returncode != 0):          
        print("The contract doesn't compile with this version of solc")
        
    else:
        flattened_contract = "flattened_"+name
        fw = open(flattened_contract,"w")
        listFiles =splitAstElements(proc.stdout.splitlines())   
        fw.write(generateFile(orderToImport(contract,listFiles),listFiles))
        fw.close()
        return flattened_contract
