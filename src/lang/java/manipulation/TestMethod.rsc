module lang::java::manipulation::TestMethod

import ParseTree;
import String;
import lang::java::\syntax::Java18;
import util::Maybe;
import util::MaybeManipulation;

public bool isMethodATest(MethodDeclaration method) {
  top-down visit(method) {
    case (Annotation) `@Test`: return true;
    case (Annotation) `@ParameterizedTest`: return true;
    case (Annotation) `@RepeatedTest(<ElementValue _>)`: return true;
  }

  return false;
}

public Identifier extractMethodName(MethodDeclaration method) {
  top-down-break visit(method) {
    case MethodHeader h: top-down-break visit(h) {
      case MethodDeclarator d: top-down-break visit(d) {
        case Identifier i: { return i; }
      }
    }
  }
}

public MethodBody extractMethodBody(MethodDeclaration method) {
  top-down-break visit(method) {
    case MethodBody b: return b;
  }
}

public MethodDeclaration replaceMethodBody(MethodDeclaration method, MethodBody newBody) {
  str newBodyStr = unparse(newBody);
  if(newBodyStr[-1] != "\n") newBody = parse(#MethodBody, unparse(newBody) + "\n");
  return top-down-break visit(method) {
    case MethodBody _ => newBody
  }
}

public list[Annotation] extractMethodAnnotations(MethodDeclaration method) {
  list[Annotation] annotations = [];

  top-down visit(method) {
    case MethodModifier m: {
      top-down-break visit(m) {
        case Annotation a: annotations += a;
      }
    }
  }

  return annotations;
}

public MethodDeclaration addMethodAnnotation(MethodDeclaration method, Annotation annotation) {
  list[MethodModifier] modifiers = [];

  top-down visit(method) {
    case MethodModifier m: modifiers += m;
  }

  MethodModifier annotationMod = parse(#MethodModifier, unparse(annotation));
  modifiers = (modifiers - terminatingModifiers()) + annotationMod + (modifiers & terminatingModifiers());

  method = top-down-break visit(method) {
    case (MethodDeclaration) `<MethodModifier* _>
                             '<MethodHeader header>
                             '<MethodBody body>` : {
                               MethodDeclaration newMethod = (MethodDeclaration) `<MethodHeader header>
                                                                                 '<MethodBody body>`;
                               insert(newMethod | addMethodModifier(it, modf) | MethodModifier modf <- modifiers);
                             }

  }

  return method;
}

public MethodDeclaration addMethodModifier(MethodDeclaration method, MethodModifier modf) {
  return top-down-break visit(method) {
    case (MethodDeclaration) `<MethodModifier* modifiers>
                             '<MethodHeader header>
                             '<MethodBody body>` => (MethodDeclaration) `<MethodModifier* modifiers>
                                                                        '<MethodModifier modf> <MethodHeader header>
                                                                        '<MethodBody body>`

  }
}

public MethodDeclaration addMethodParameter(MethodDeclaration method, FormalParameter parameterToAdd) {
  MethodDeclarator declarator;
  top-down-break visit(method) {
    case MethodDeclarator d: declarator = d;
  }

  Identifier methodId = extractMethodName(method);

  list[FormalParameter] methodParameters = [];
  Maybe[LastFormalParameter] finalParameter = nothing();
  Maybe[Dims] dims = nothing();
  top-down visit(declarator) {
    case FormalParameter f: methodParameters += f;
    case LastFormalParameter f: finalParameter = just(f);
    case Dims d: dims = just(d);
  }

  methodParameters += parameterToAdd;
  MethodDeclarator newDeclarator = buildMethodDeclarator(methodId, methodParameters, finalParameter, dims);

  return top-down-break visit(method) {
    case MethodDeclarator _ => newDeclarator
  }
}

private MethodDeclarator buildMethodDeclarator(
    Identifier methodId,
    list[FormalParameter] parameters,
    Maybe[LastFormalParameter] finalParameter,
    Maybe[Dims] dims
  ) {
  str methodDeclarator = unparse(methodId) + "(";
  str paramSeparator = ", ";

  methodDeclarator += ("" |
                          it + unparse(param) + paramSeparator |
                          FormalParameter param <- parameters);

  if(isSomething(finalParameter)) {
    parametersStr += unparse(unwrap(finalParameter));
  } else {
    if(endsWith(methodDeclarator, paramSeparator)) methodDeclarator = methodDeclarator[..-size(paramSeparator)];
  }
  methodDeclarator += ")";

  if(isSomething(dims)) methodDeclarator += " " + unparse(unwrap(dims));

  return parse(#MethodDeclarator, methodDeclarator);
}

private list[MethodModifier] terminatingModifiers() {
  return [
    (MethodModifier) `public`,
    (MethodModifier) `protected`,
    (MethodModifier) `private`,
    (MethodModifier) `abstract`,
    (MethodModifier) `static`,
    (MethodModifier) `final`,
    (MethodModifier) `synchronized`,
    (MethodModifier) `native`,
    (MethodModifier) `strictfp`
  ];
}
