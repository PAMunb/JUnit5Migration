module lang::java::manipulation::TestMethod

import ParseTree;
import lang::java::\syntax::Java18; 

public bool isMethodATest(MethodDeclaration method) {
  top-down visit(method) {
    case (Annotation) `@Test`: return true; 
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
        case Annotation a: annotations = annotations + a;
      }
    }
  }

  return annotations;
}

public MethodDeclaration addMethodAnnotation(MethodDeclaration method, Annotation annotation) {
  list[MethodModifier] modifiers = [];

  top-down visit(method) {
    case MethodModifier m: modifiers = modifiers + m;
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
