#import "ObjectTesting.h"
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSPointerFunctions.h>
#import <Foundation/NSValue.h>

static void
testHashFunction(NSPointerFunctions *pf, const char *name,
  const void *item1, const void *item2, const void *item3)
{
  NSUInteger            (*hashFunction)\
  (const void *item, NSUInteger (*size)(const void *item));
  NSUInteger            (*sizeFunction)(const void *item);

  hashFunction = [pf hashFunction];
  sizeFunction = [pf sizeFunction];

  PASS(hashFunction(item1, sizeFunction) == hashFunction(item2, sizeFunction),
    "%s item1 hash equal to item2 hash", name)
  PASS(hashFunction(item1, sizeFunction) != hashFunction(item3, sizeFunction),
    "%s item1 hash not equal to item3 hash", name)
}

static void
testIsEqualFunction(NSPointerFunctions *pf, const char *name,
  const void *item1, const void *item2, const void *item3)
{
  NSUInteger            (*hashFunction)\
  (const void *item, NSUInteger (*size)(const void *item));
  BOOL                  (*isEqualFunction)\
  (const void *item1, const void *item2, NSUInteger (*size)(const void *item));
  NSUInteger            (*sizeFunction)(const void *item);

  isEqualFunction = [pf isEqualFunction];
  sizeFunction = [pf sizeFunction];

  PASS(isEqualFunction(item1, item2, sizeFunction),
    "%s item1 is equal to item2", name)
  PASS(!isEqualFunction(item1, item3, sizeFunction),
    "%s item1 is not equal to item3", name)
}

/* For struct personality
 */
typedef struct {
  bool aBool;
  int anInt;
  char aChar;
} aStructType;

static NSUInteger aStructSize(const void *item)
{
  return sizeof(aStructType);
}

/* All instanced of the GSEqualInstances class are considered equal
 * and have the same hash.
 */
@interface      GSEqualInstances : NSObject
@end
@implementation GSEqualInstances
- (NSUInteger) hash
{
  return 1;
}
- (BOOL) isEqual: (id)other
{
  return [other isKindOfClass: [self class]];
}
@end
 



int main()
{
  NSAutoreleasePool     *arp = [NSAutoreleasePool new];
  NSPointerFunctions    *pf;

  void                  *(*acquireFunction)\
  (const void *src, NSUInteger (*size)(const void *item), BOOL shouldCopy);
  NSUInteger            (*hashFunction)\
  (const void *item, NSUInteger (*size)(const void *item));
  BOOL                  (*isEqualFunction)\
  (const void *item1, const void *item2, NSUInteger (*size)(const void *item));
  NSString              *(*descriptionFunction)(const void *item);
  void                  (*relinquishFunction)\
  (const void *item, NSUInteger (*size)(const void *item));
  NSUInteger            (*sizeFunction)(const void *item);

  START_SET("Personality/Memory")
  PASS(nil == [NSPointerFunctions pointerFunctionsWithOptions:
    NSPointerFunctionsIntegerPersonality],
    "nil on create with integer personality and wrong memory")
  END_SET("Personality/Memory")

  START_SET("CStringPersonality")
    {
      const char    *cstr1 = "hello";
      const char    *cstr2 = "hello";
      const char    *cstr3 = "goodbye";

      pf = [NSPointerFunctions pointerFunctionsWithOptions:
        NSPointerFunctionsCStringPersonality];

      testIsEqualFunction(pf, "CStringPersonality", cstr1, cstr2, cstr3);
      testHashFunction(pf, "CStringPersonality", cstr1, cstr2, cstr3);

      PASS_EQUAL([pf descriptionFunction](cstr1),
        [NSString stringWithUTF8String: cstr1],
        "CStringPersonality description")
    }
  END_SET("CStringPersonality")

  START_SET("IntegerPersonality")
    {
      const void *int1 = (const void*)4321;
      const void *int2 = (const void*)4321;
      const void *int3 = (const void*)1234;

      pf = [NSPointerFunctions pointerFunctionsWithOptions:
        NSPointerFunctionsOpaqueMemory | NSPointerFunctionsIntegerPersonality];

      testIsEqualFunction(pf, "IntegerPersonality", int1, int2, int3);
      testHashFunction(pf, "IntegerPersonality", int1, int2, int3);
    }
  END_SET("IntegerPersonality")

  START_SET("ObjectPersonality")
    {
      id        obj1 = @"hello";
      id        obj2 = @"hello";
      id        obj3 = [NSNumber numberWithInt: 42];

      pf = [NSPointerFunctions pointerFunctionsWithOptions:
        NSPointerFunctionsObjectPersonality];

      testIsEqualFunction(pf, "ObjectPersonality", obj1, obj2, obj3);
      testHashFunction(pf, "ObjectPersonality", obj1, obj2, obj3);

      PASS_EQUAL([pf descriptionFunction](obj1), obj1,
        "ObjectPersonality string description")
      PASS_EQUAL([pf descriptionFunction](obj3), @"42",
        "ObjectPersonality number description")
    }
  END_SET("ObjectPersonality")

  START_SET("ObjectPointerPersonality")
    {
      id        obj1 = AUTORELEASE([GSEqualInstances new]);
      id        obj2 = obj1;
      id        obj3 = AUTORELEASE([GSEqualInstances new]);

      pf = [NSPointerFunctions pointerFunctionsWithOptions:
        NSPointerFunctionsObjectPointerPersonality];

      /* Here obj1 and obj3 have the same -hash and compare the same
       * for -isEqual:,  but if the pointer functions are working
       * properly they will have different hash/equality because
       * pointer value and identity shoud be used.
       */
      testIsEqualFunction(pf, "ObjectPointerPersonality", obj1, obj2, obj3);
      testHashFunction(pf, "ObjectPointerPersonality", obj1, obj2, obj3);
    }
  END_SET("ObjectPointerPersonality")

  START_SET("OpaquePersonality")
    {
      const void *ptr1 = (const void*)4321;
      const void *ptr2 = ptr1;
      const void *ptr3 = (const void*)1234;

      pf = [NSPointerFunctions pointerFunctionsWithOptions:
        NSPointerFunctionsOpaquePersonality];

      testIsEqualFunction(pf, "OpaquePersonality", ptr1, ptr2, ptr3);
      testHashFunction(pf, "OpaquePersonality", ptr1, ptr2, ptr3);
    }
  END_SET("OpaquePersonality")

  START_SET("StructPersonality")
    {
      aStructType s1 = { NO, 24, 'n' };
      aStructType s2 = { NO, 24, 'n' };
      aStructType s3 = { YES, 42, 'y' };

      pf = [NSPointerFunctions pointerFunctionsWithOptions:
        NSPointerFunctionsStructPersonality];
      [pf setSizeFunction: &aStructSize];

      testIsEqualFunction(pf, "StructPersonality", &s1, &s2, &s3);
      testHashFunction(pf, "StructPersonality", &s1, &s2, &s3);
    }
  END_SET("StructPersonality")


  [arp release]; arp = nil;
  return 0;
} 

