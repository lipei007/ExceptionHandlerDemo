//
//  ViewController.m
//  ExceptionHandlerDemo
//
//  Created by Jack on 2018/8/2.
//  Copyright © 2018年 emerys. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    id a = nil;
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject:a];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
