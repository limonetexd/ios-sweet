/* Host probe (macOS Metal): what -newFunctionWithName:constantValues: hands back.
 * Build/run: clang -fobjc-arc -framework Metal -framework Foundation fc-specialize-probe.m -o /tmp/p && (cd /tmp && ./p)
 * then: llvm-dis {base,empty,set}.air. Writes *.air and airScript.txt into the cwd.
 * 2026-11-21 (macOS 15.7, x86_64): specialized functions carry FOLDED AIR, no air.function_constants. */
#import <Metal/Metal.h>
#import <objc/message.h>
static NSString *src = @
"#include <metal_stdlib>\nusing namespace metal;\n"
"constant int fc_blend [[function_constant(0)]];\n"
"constant bool fc_flag [[function_constant(1)]];\n"
"struct V { float4 p [[position]]; float4 c; };\n"
"fragment float4 fs(V in [[stage_in]]) {\n"
"  int b = is_function_constant_defined(fc_blend) ? fc_blend : 54;\n"
"  float4 r = (b == 54) ? in.c : float4(b / 255.0);\n"
"  if (fc_flag) r.a = 0.5;\n"
"  return r;\n}\n";
static void dump(NSString *tag, id f) {
	printf("%s: %s %p", tag.UTF8String, object_getClassName(f), f);
	SEL s[] = { sel_getUid("bitcodeData"), sel_getUid("specializationAirScript"),
	            sel_getUid("functionConstantsDictionary"), sel_getUid("baseFunctionConstantValues") };
	const char *n[] = { "bitcode", "airScript", "fcDict", "baseValues" };
	for (int i = 0; i < 4; i++) {
		if (![f respondsToSelector:s[i]]) { printf(" %s=n/a", n[i]); continue; }
		id o = ((id (*)(id, SEL))objc_msgSend)(f, s[i]);
		if ([o isKindOfClass:[NSData class]]) {
			printf(" %s=%lu B", n[i], (unsigned long)[o length]);
			if (i == 0) [o writeToFile:[tag stringByAppendingString:@".air"] atomically:NO];
		} else if ([o respondsToSelector:@selector(count)]) printf(" %s=%lu", n[i], (unsigned long)[o count]);
		else printf(" %s=%s", n[i], o ? object_getClassName(o) : "nil");
		if (i == 1 && o) [[o description] writeToFile:@"airScript.txt" atomically:NO encoding:NSUTF8StringEncoding error:nil];
	}
	printf("\n");
}
int main(void) { @autoreleasepool {
	id<MTLDevice> d = MTLCreateSystemDefaultDevice();
	NSError *e = nil;
	id<MTLLibrary> lib = [d newLibraryWithSource:src options:nil error:&e];
	if (!lib) { printf("lib: %s\n", e.description.UTF8String); return 1; }
	dump(@"base", [lib newFunctionWithName:@"fs"]);
	MTLFunctionConstantValues *cv = [MTLFunctionConstantValues new];
	id f = [lib newFunctionWithName:@"fs" constantValues:cv error:&e];
	if (f) dump(@"empty", f); else printf("empty: nil %s\n", e.description.UTF8String);
	int v = 7; bool t = true;
	[cv setConstantValue:&v type:MTLDataTypeInt atIndex:0];
	[cv setConstantValue:&t type:MTLDataTypeBool atIndex:1];
	f = [lib newFunctionWithName:@"fs" constantValues:cv error:&e];
	if (f) dump(@"set", f); else printf("set: nil %s\n", e.description.UTF8String);
}}
