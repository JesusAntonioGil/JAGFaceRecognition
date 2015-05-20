//
//  UIImageViewFaceRecognition.m
//  UImageViewFaceRecognition
//
//  Created by Jesus Antonio Gil on 20/5/15.
//  Copyright (c) 2015 Jesus Antonio Gil. All rights reserved.
//

#import "JAGFaceRecognition.h"


@interface JAGFaceRecognition ()

@property (strong, nonatomic) UIImageView *imageViewDetected;
@property (strong, nonatomic) NSArray *faces;

@property (strong, nonatomic) CIDetector *faceDetector;
@property (strong, nonatomic) CIImage *beginImage;

@end


@implementation JAGFaceRecognition

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        self.faceBorderColor = [UIColor whiteColor];
        self.faceBorderWidth = 1.0f;
    }
    
    return self;
}

#pragma mark - ACCESSORS

- (CIDetector *)faceDetector
{
    if(!_faceDetector)
    {
        NSDictionary *detectorOptions = [NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy];
        _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:CIContext.new options:detectorOptions];
    }
    
    return _faceDetector;
}

- (NSArray *)faces
{
    if(!_faces)
    {
        _faces = NSArray.new;
    }
    
    return _faces;
}

#pragma mark - ACTIONS

- (void)onFaceAnnotationTap:(id)sender
{
    if([self.delegate respondsToSelector:@selector(faceRecognition:face:)])
    {
        [self.delegate faceRecognition:self face:nil];
    }
}

#pragma mark - PUBLIC

- (void)faceDetectorWithImageView:(UIImageView *)imageView completion:(JAGFaceRecognitionCompletion)completion
{
    if(!imageView)
    {
        completion(NO, nil, nil);
        return;
    }
    
    self.imageViewDetected = imageView;
    self.imageViewDetected.userInteractionEnabled = YES;
    self.beginImage = [CIImage imageWithCGImage:[self resizeImage:imageView.image].CGImage];
    
    [self addAnotationsToImageView];
    
    completion(YES, self.imageViewDetected, self.faces);
}

#pragma mark - PRIVATE
#pragma mark - Image resize

-(UIImage *)resizeImage:(UIImage *)img
{
    CGSize size = self.imageViewDetected.frame.size;
    size.height = (img.size.height / img.size.width) * self.imageViewDetected.frame.size.width;
    
    CGRect rect = self.imageViewDetected.frame;
    rect.size = size;
    self.imageViewDetected.frame = rect;
    
    UIGraphicsBeginImageContext(size);
    [img drawInRect:CGRectMake(0,0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

#pragma mark - Faces

- (NSArray *)detectFaces
{
    NSArray *features = [JAGFaceFeature getFaceFeatures:[self.faceDetector featuresInImage:self.beginImage]];
    return features;
}

- (void)addAnotationsToImageView
{
    self.faces = [self detectFaces];
    
    CGAffineTransform transform = CGAffineTransformMakeScale(1, -1);
    transform = CGAffineTransformTranslate(transform, 0.0, -self.imageViewDetected.bounds.size.height);
    
    for(CIFaceFeature *face in self.faces)
    {
        const CGRect faceRect = CGRectApplyAffineTransform(face.bounds, transform);
        [self.imageViewDetected addSubview:[self getAnnotationViewWithRect:faceRect]];
    }
}

- (UIView *)getAnnotationViewWithRect:(CGRect)rect
{
    UIView *annotationView = [[UIView alloc] initWithFrame:rect];
    annotationView.userInteractionEnabled = YES;
    annotationView.backgroundColor = [UIColor clearColor];
    annotationView.layer.borderWidth = self.faceBorderWidth;
    annotationView.layer.borderColor = self.faceBorderColor.CGColor;
    if(self.faceRounded)
    {
        annotationView.layer.cornerRadius = annotationView.frame.size.height / 2;
    }
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onFaceAnnotationTap:)];
    [annotationView addGestureRecognizer:tapGesture];
    
    return annotationView;
}

@end
