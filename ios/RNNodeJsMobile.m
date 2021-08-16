
#import "RNNodeJsMobile.h"
#import "NodeRunner.hpp"
#import <React/RCTEventDispatcher.h>


@implementation RNNodeJsMobile

NSString* const BUILTIN_MODULES_RESOURCE_PATH = @"builtin_modules";
NSString* const NODEJS_PROJECT_RESOURCE_PATH = @"nodejs-project";
NSString* const NODEJS_DLOPEN_OVERRIDE_FILENAME = @"override-dlopen-paths-preload.js";
NSString* nodePath;

@synthesize bridge = _bridge;

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (id)init
{
  self = [super init];
  if (self != nil)
  {
    [[NodeRunner sharedInstance] setCurrentRNNodeJsMobile:self];
  }

  NSString* builtinModulesPath = [[NSBundle mainBundle] pathForResource:BUILTIN_MODULES_RESOURCE_PATH ofType:@""];
  nodePath = [[NSBundle mainBundle] pathForResource:NODEJS_PROJECT_RESOURCE_PATH ofType:@""];
  nodePath = [nodePath stringByAppendingString:@":"];
  nodePath = [nodePath stringByAppendingString:builtinModulesPath];
  
  return self;
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(sendMessage:(NSString *)channelName:(NSString *)message)
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    [[NodeRunner sharedInstance] sendMessageToNode:channelName:message];
  });
}

-(void)callStartNodeWithScript:(NSString *)script
{
  NSArray* nodeArguments = nil;

  NSString* dlopenoverridePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@/%@", NODEJS_PROJECT_RESOURCE_PATH, NODEJS_DLOPEN_OVERRIDE_FILENAME] ofType:@""];
  // Check if the file to override dlopen lookup exists, for loading native modules from the Frameworks.
  if(!dlopenoverridePath)
  {
    nodeArguments = [NSArray arrayWithObjects:
                              @"node",
                              @"-e",
                              script,
                              nil
                              ];
  } else {
    nodeArguments = [NSArray arrayWithObjects:
                              @"node",
                              @"-r",
                              dlopenoverridePath,
                              @"-e",
                              script,
                              nil
                              ];
  }
  [[NodeRunner sharedInstance] startEngineWithArguments:nodeArguments:nodePath];
}

-(void)callStartNodeProject:(NSString *)mainFileName
{
  NSString* srcPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@/%@", NODEJS_PROJECT_RESOURCE_PATH, mainFileName] ofType:@""];
  NSArray* nodeArguments = nil;

  NSString* dlopenoverridePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@/%@", NODEJS_PROJECT_RESOURCE_PATH, NODEJS_DLOPEN_OVERRIDE_FILENAME] ofType:@""];
  // Check if the file to override dlopen lookup exists, for loading native modules from the Frameworks.
  if(!dlopenoverridePath)
  {
    nodeArguments = [NSArray arrayWithObjects:
                              @"node",
                              srcPath,
                              nil
                              ];
  } else {
    nodeArguments = [NSArray arrayWithObjects:
                              @"node",
                              @"-r",
                              dlopenoverridePath,
                              srcPath,
                              nil
                              ];
  }
  [[NodeRunner sharedInstance] startEngineWithArguments:nodeArguments:nodePath];
}

-(void)callStartNodeProjectWithArgs:(NSDictionary *)dict
{
  NSString* srcPath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@/%@", NODEJS_PROJECT_RESOURCE_PATH, dict[@"mainFileName"]] ofType:@""];
  NSMutableArray* nodeArguments = nil;

  NSString* dlopenoverridePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%@/%@", NODEJS_PROJECT_RESOURCE_PATH, NODEJS_DLOPEN_OVERRIDE_FILENAME] ofType:@""];
  // Check if the file to override dlopen lookup exists, for loading native modules from the Frameworks.
  if(!dlopenoverridePath)
  {
    nodeArguments = [NSMutableArray arrayWithObjects:
                              @"node",
                              srcPath,
                              ];

    [nodeArguments addObjectsFromArray:dict[@"args"]];
    
    [nodeArguments addObject:nil];

  } else {
    nodeArguments = [NSMutableArray arrayWithObjects:
                              @"node",
                              @"-r",
                              dlopenoverridePath,
                              srcPath,
                              nil
                              ];
  }
  [[NodeRunner sharedInstance] startEngineWithArguments:nodeArguments:nodePath];
}

RCT_EXPORT_METHOD(startNodeWithScript:(NSString *)script options:(NSDictionary *)options)
{
  if(![NodeRunner sharedInstance].startedNodeAlready)
  {
    [NodeRunner sharedInstance].startedNodeAlready=true;
    NSThread* nodejsThread = nil;
    nodejsThread = [[NSThread alloc]
      initWithTarget:self
      selector:@selector(callStartNodeWithScript:)
      object:script
    ];
    // Set 2MB of stack space for the Node.js thread.
    [nodejsThread setStackSize:2*1024*1024];
    [nodejsThread start];
  }
}

RCT_EXPORT_METHOD(startNodeProject:(NSString *)mainFileName options:(NSDictionary *)options)
{
  if(![NodeRunner sharedInstance].startedNodeAlready)
  {
    [NodeRunner sharedInstance].startedNodeAlready=true;
    NSThread* nodejsThread = nil;
    nodejsThread = [[NSThread alloc]
      initWithTarget:self
      selector:@selector(callStartNodeProject:)
      object:mainFileName
    ];
    // Set 2MB of stack space for the Node.js thread.
    [nodejsThread setStackSize:2*1024*1024];
    [nodejsThread start];
  }
}

RCT_EXPORT_METHOD(startNodeProjectWithArgs:(NSString *)mainFileName options:(NSDictionary *)options args:(NSArray *)args)
{
  if(![NodeRunner sharedInstance].startedNodeAlready)
  {
    // NSMutableArray * arguments = [NSMutableArray array];
    // if(args)
    // {
    //   [arguments addObject:args];
    //   id argument;
    //   va_list argsList;
    //   va_start(argsList, args);
    //   while(argument = va_arg(argsList, NSString))
    //   {
    //     [arguments addObject:argument];
    //   }
    //   va_end(argsList);
    // }
    [NodeRunner sharedInstance].startedNodeAlready=true;
    NSThread* nodejsThread = nil;
    nodejsThread = [[NSThread alloc]
      initWithTarget:self
      selector:@selector(callStartNodeProjectWithArgs:)
      object:@{@"mainFileName":mainFileName,@"args":args}
    ];
    // Set 2MB of stack space for the Node.js thread.
    [nodejsThread setStackSize:2*1024*1024];
    [nodejsThread start];
  }
}

-(void) sendMessageBackToReact:(NSString*)channelName:(NSString*)message
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    [self.bridge.eventDispatcher sendAppEventWithName:@"nodejs-mobile-react-native-message"
      body:@{@"channelName": channelName, @"message": message}
    ];
  });
}

@end

