/* Host probe (macOS Metal): specialize ONE function of a .metallib and dump its bitcode.
 *   clang -fobjc-arc -framework Metal -framework Foundation fc-specialize-lib.m -o /tmp/fcs
 *   cd /tmp && ./fcs LIB.metallib FUNCTION [NAME=U8 | NAME]...
 * Writes base.air (newFunctionWithName:) and empty.air (no constants) or set.air (NAME=U8 sets a
 * uchar constant, a bare NAME a bool true) into the cwd; then llvm-dis or air2nir.
 * 2026-11-22 (macOS 15.7): QuartzCore fixed_frag_lph_cph with no constants specializes to NO
 * colour outputs (frg_has_color0 folds false); with fc_dest_index=0 it returns color0 = the colour
 * varying (RESEARCH_LEDGER). The metallib is Apple's: keep it and the outputs out of the repo. */
#import <Metal/Metal.h>
#import <objc/message.h>
static void dump(const char *tag, id f) {
	if (!f) { printf("%s: nil\n", tag); return; }
	id o = ((id (*)(id, SEL))objc_msgSend)(f, sel_getUid("bitcodeData"));
	printf("%s: %s bitcode=%lu B\n", tag, object_getClassName(f), (unsigned long)[o length]);
	[o writeToFile:[NSString stringWithFormat:@"%s.air", tag] atomically:NO];
}
int main(int argc, char **argv) { @autoreleasepool {
	id<MTLDevice> d = MTLCreateSystemDefaultDevice();
	NSError *e = nil;
	id<MTLLibrary> lib = [d newLibraryWithURL:[NSURL fileURLWithPath:@(argv[1])] error:&e];
	if (!lib) { printf("lib: %s\n", e.description.UTF8String); return 1; }
	NSString *n = @(argv[2]);
	dump("base", [lib newFunctionWithName:n]);
	e = nil;
	MTLFunctionConstantValues *cv = [MTLFunctionConstantValues new];
	for (int i = 3; i < argc; i++) {   /* NAME=U8VALUE (uchar) or NAME (bool true) */
		char nm[128]; unsigned v = 0; const char *eq = strchr(argv[i], '=');
		if (eq) { snprintf(nm, sizeof(nm), "%.*s", (int)(eq - argv[i]), argv[i]); v = (unsigned)atoi(eq + 1);
			uint8_t b = (uint8_t)v; [cv setConstantValue:&b type:MTLDataTypeUChar withName:@(nm)]; printf("set %s = (uchar)%u\n", nm, v); }
		else { bool y = true; [cv setConstantValue:&y type:MTLDataTypeBool withName:@(argv[i])]; printf("set %s = true\n", argv[i]); } }
	id f = [lib newFunctionWithName:n constantValues:cv error:&e];
	if (!f) printf("empty: %s\n", e.description.UTF8String);
	dump(argc > 3 ? "set" : "empty", f);
} return 0; }
