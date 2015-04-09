//
//  ViewController.m
//  ConvertCueFromGBToUTF8
//
//  Created by Carmelo Sui on 4/9/15.
//  Copyright (c) 2015 Carmelo Sui. All rights reserved.
//

#import "ViewController.h"

#define TRY_STOP_AND_RETURN_IF_NEEDED do {if (self.tryingStopping) {[self convertingStopped]; return;}} while(0)

@interface ViewController ()

@property (weak) IBOutlet NSTextField *filePathTextField;
@property (weak) IBOutlet NSButton *convertRecursivelyCheckbox;
@property (weak) IBOutlet NSButton *startConvertButton;
@property (strong) IBOutlet NSTextView *outputTextField;
@property (weak) IBOutlet NSButton *chooseFileButton;

@property (assign) BOOL recursivelyConvertingThisTime;
@property (nonatomic, assign, getter=isConverting) BOOL converting;
@property (nonatomic, assign) BOOL tryingStopping;
@property (nonatomic, strong) dispatch_queue_t convertingSerialQueue;
@property (nonatomic, strong) NSMutableSet *convertingTasks;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.convertingSerialQueue = dispatch_queue_create("cue converting queue", NULL);
    self.convertingTasks = [NSMutableSet set];
}

- (IBAction)startConvertButtonPressed:(id)sender {
    if (self.isConverting) {
        [self stopConverting];
    }
    else {
        [self startConverting];
    }
}

- (IBAction)chooseFile:(id)sender {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Select"];
    
    if ([openPanel runModal] == NSModalResponseOK)
    {
        NSArray* files = [openPanel URLs];
        if (files.count == 0) {
            return;
        }
        self.filePathTextField.stringValue = [files.lastObject path];
    }
}

- (void)stopConverting
{
    self.tryingStopping = YES;
}

-(void)startConverting
{
    [self convertingStarted];
    NSString *path = self.filePathTextField.stringValue;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL pathIsDirectory = NO;
    BOOL fileExist = [fileManager fileExistsAtPath:path isDirectory:&pathIsDirectory];
    if (!fileExist) {
        [self outputError:[NSString stringWithFormat:@"file not exist \"%@\"", path]];
        [self convertingStopped];
        return;
    }
    
    if (pathIsDirectory) {
        self.recursivelyConvertingThisTime = (self.convertRecursivelyCheckbox.state == NSOnState);
        dispatch_async(self.convertingSerialQueue, ^{
            [self convertDirectory:path];
            [self convertingStopped];
        });
        return;
    }
    
    dispatch_async(self.convertingSerialQueue, ^{
        [self convertFile:path];
        [self convertingStopped];
    });
}

-(void)convertingStarted
{
    self.converting = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.startConvertButton.title = @"stop";
        self.chooseFileButton.enabled = NO;
    });
}

-(void)convertingStopped
{
    self.converting = NO;
    self.tryingStopping = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.startConvertButton.title = @"start convert";
        self.chooseFileButton.enabled = YES;
    });
}

- (void)convertDirectory:(NSString*)directory
{
    TRY_STOP_AND_RETURN_IF_NEEDED;
    
    sleep(5);
    
    NSError *error = nil;
    NSArray *contentsOfDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:&error];
    if (error) {
        [self outputError:[NSString stringWithFormat:@"directory convert failed \"%@\"", directory]];
        return;
    }
    
    for (NSString *path in contentsOfDirectory) {
        TRY_STOP_AND_RETURN_IF_NEEDED;
        
        NSString *fullPath = [directory stringByAppendingPathComponent:path];
        BOOL isDirectory = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDirectory];
        NSMutableArray *subDirectories = [NSMutableArray array];
        if (isDirectory) {
            [subDirectories addObject:fullPath];
        }
        else {
            [self convertFile:fullPath];
        }
        if (self.recursivelyConvertingThisTime) {
            for (NSString *directory in subDirectories) {
                TRY_STOP_AND_RETURN_IF_NEEDED;
                
                [self convertDirectory:directory];
            }
        }
    }
}

- (BOOL)fileTypeIsForConvert:(NSString*)path
{
    return [path.pathExtension isEqualTo:@"cue"];
}

- (void)convertFile:(NSString*)path
{
    TRY_STOP_AND_RETURN_IF_NEEDED;
    
    if (![self fileTypeIsForConvert:path]) {
        return;
    }
    
    NSError *error = nil;
    NSString *fileContent = [NSString stringWithContentsOfFile:path encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGBK_95) error:&error];
    if (error) {
        [self outputFileConvertingFail:path];
        return;
    }
    
    BOOL succeed = [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (succeed) {
        [self outputLog:[NSString stringWithFormat:@"file converting succeeded \"%@\"", path]];
    }
    else {
        [self outputFileConvertingFail:path];
    }
}

-(void)outputFileConvertingFail:(NSString*)path
{
    [self outputError:[NSString stringWithFormat:@"file \"%@\" converting failed",path]];
}

-(void)outputLog:(NSString*)log
{
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:log attributes:@{NSForegroundColorAttributeName: [NSColor blackColor]}];
    [self appendToTextView:string];
}

-(void)outputError:(NSString*)error
{
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:error attributes:@{NSForegroundColorAttributeName: [NSColor redColor]}];
    [self appendToTextView:string];
}

- (void)appendToTextView:(NSAttributedString*)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self.outputTextField textStorage] appendAttributedString:text];
        [self.outputTextField scrollRangeToVisible:NSMakeRange([[self.outputTextField string] length], 0)];
    });
}

@end
