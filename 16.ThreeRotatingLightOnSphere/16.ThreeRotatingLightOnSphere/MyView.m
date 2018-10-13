//
//  MyView.m
//  3.TriangleOrtho
//
//  Created by Vaibhav Zodge on 07/06/18.
//  Copyright © 2018 Vaibhav Zodge. All rights reserved.
//

#import "MyView.h"

enum
{
    VVZ_ATTRIBUTE_VERTEX = 0,
    VVZ_ATTRIBUTE_COLOR,
    VVZ_ATTRIBUTE_NORMAL,
    VVZ_ATTRIBUTE_TEXTURE0,
};

@implementation MyView
{
    EAGLContext *eaglContext; //opengl context
    
    GLuint defaultFramebuffer; // frame buffer bind
    GLuint colorRenderbuffer;
    GLuint depthRenderbuffer;
    
    id displayLink; //CADisplayLink *displayLink
    NSInteger animationFrameInterval;
    BOOL isAnimating;
    
    GLuint vertextShaderObject;
    GLuint fragmentShaderObject;
    GLuint shaderProgramObject;

    GLuint gNumElements;
    GLuint gNumVertices;
    float sphere_vertices[1146];
    float sphere_normals[1146];
    float sphere_textures[764];
    
    short sphere_elements[2280];
    
    
    GLuint gVao_sphere;
    GLuint gVbo_sphere_position;
    GLuint gVbo_sphere_normal;
    GLuint gVbo_sphere_element;

    GLfloat angleRotateRed;
    GLfloat angleRotateGreen;
    GLfloat angleRotateBlue;
    
    GLuint model_matrix_uniform, view_matrix_uniform, projection_matrix_uniform;
    
    GLuint La_uniform;
    GLuint Ls_uniform;
    
    GLuint Ld_uniform_red;
    GLuint light_position_uniform_red;
    
    GLuint Ld_uniform_green;
    GLuint light_position_uniform_green;
    
    GLuint Ld_uniform_blue;
    GLuint light_position_uniform_blue;
    
    GLuint Ka_uniform;
    GLuint Kd_uniform;
    GLuint Ks_uniform;
    GLuint material_shininess_uniform;
    
    GLuint gLKeyPressedUniform;
    
    bool gbLight, bIsLKeyPressed;
    
    vmath::mat4 gPerspectiveProjectionMatrix;


}


-(id)initWithFrame:(CGRect)frame;
{
    
    self=[super initWithFrame:frame];
    
    if(self)
    {
        CAEAGLLayer *eaglLayer=(CAEAGLLayer *)super.layer; //super, give me  animation layer
        //super.layer  , this . Syntax called property Syntax
        // it can be written ad [super layer]
        // properties are in Objective C are by default get and set methods. We dont need to explicitly mention get but need to mention for set.
        //layer is nothing but pixelFormatAttribute
        
        eaglLayer.opaque=YES;  //[eaglLayer setOpaque:YES]
        eaglLayer.drawableProperties=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:FALSE],
                                      kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat,nil];
        //retain backing means, do you want to retain the property, we say no ad we are animation
        //color format is 32  rgba8
        
        eaglContext=[[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3]; // create opengl context of version OpenGLES 3
        if(eaglContext==nil)
        {
            [self release];
            return(nil);
        }
        [EAGLContext setCurrentContext:eaglContext]; //set opengl context with current context
        //setCurrentContext is static method
        
        //************************ Frame buffer creation
        
        glGenFramebuffers(1,&defaultFramebuffer); // generate frame buffer
        glBindFramebuffer(GL_FRAMEBUFFER,defaultFramebuffer);
        //outer circle of buffer creation done, draw by sir
        
        // rendering api to store so created buffer called renderer buffer
        glGenRenderbuffers(1,&colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER,colorRenderbuffer);
        //inner circle draw by sir for color buffer (or depth buffer)
        
        //context what are you going to store in render buffer? GL_RENDERBUFFER
        //From where will you get data, fromDrawable
        [eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
        
        //attach colorRenderBuffer to a specific point (receptor). Where should I store color buffer (small circle) in frame buffer (big circle)
        glFramebufferRenderbuffer(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0,GL_RENDERBUFFER,colorRenderbuffer);
        
        
        //*************** enable depth (or set depth buffer in frame buffer)
        GLint backingWidth;
        GLint backingHeight;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER,GL_RENDERBUFFER_WIDTH,&backingWidth);// get width of render buffer, it gives by cgl/agl
        glGetRenderbufferParameteriv(GL_RENDERBUFFER,GL_RENDERBUFFER_HEIGHT,&backingHeight);
        
        glGenRenderbuffers(1,&depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER,depthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER,GL_DEPTH_COMPONENT16,backingWidth,backingHeight);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER,GL_DEPTH_ATTACHMENT,GL_RENDERBUFFER,depthRenderbuffer);
        
        if(glCheckFramebufferStatus(GL_FRAMEBUFFER)!=GL_FRAMEBUFFER_COMPLETE)
        {
            printf("Failed To Create Complete Framebuffer Object %x\n",glCheckFramebufferStatus(GL_FRAMEBUFFER));
            glDeleteFramebuffers(1,&defaultFramebuffer);
            glDeleteRenderbuffers(1,&colorRenderbuffer);
            glDeleteRenderbuffers(1,&depthRenderbuffer);
            [self release] ;
            return(nil);
        }
        
        printf("Renderer : %s | GL Version : %s | GLSL Version : %s\n",glGetString(GL_RENDERER),glGetString(GL_VERSION),glGetString(GL_SHADING_LANGUAGE_VERSION));
        
        // hard coded initializations
        isAnimating=NO;
        animationFrameInterval=60; // default since iOS 8.2, frame per second. Before 8.2 it was 30. It set to 60 because HD's frame rate is 60
        
        // *************************** shader program start
        
        
        //**************************************** Vertex shader **********************************************
        vertextShaderObject = glCreateShader(GL_VERTEX_SHADER);
        
        const GLchar *vertexShaderSourceCode =
        "#version 300 es"\
        "\n"\
        "in vec4 vPosition;" \
        "in vec3 vNormal;" \
        "uniform mat4 u_model_matrix;" \
        "uniform mat4 u_view_matrix;" \
        "uniform mat4 u_projection_matrix;" \
        "uniform vec4 u_light_position_red;" \
        "uniform vec4 u_light_position_green;" \
        "uniform vec4 u_light_position_blue;" \
        "uniform int u_lighting_enabled;" \
        "out vec3 transformed_normals;" \
        "out vec3 light_direction_red;" \
        "out vec3 light_direction_green;" \
        "out vec3 light_direction_blue;" \
        "out vec3 viewer_vector;" \
        "void main(void)" \
        "{" \
        "if(u_lighting_enabled==1)" \
        "{" \
        "vec4 eye_coordinates=u_view_matrix * u_model_matrix * vPosition;" \
        "transformed_normals=mat3(u_view_matrix * u_model_matrix) * vNormal;" \
        "light_direction_red = vec3(u_light_position_red) - eye_coordinates.xyz;"\
        "light_direction_green = vec3(u_light_position_green) - eye_coordinates.xyz;"\
        "light_direction_blue = vec3(u_light_position_blue) - eye_coordinates.xyz;"\
        "viewer_vector = -eye_coordinates.xyz;" \
        "}" \
        "gl_Position=u_projection_matrix * u_view_matrix * u_model_matrix * vPosition;" \
        "}";



        

        
        /*
         Steps to calculate defuse light (this is done in vertex shader), it is done using observational mathmatics
         1. First geometry position coordinate covert to eye space (eye co-ordinates)
         2. Calculate Normal matrix, which is required to convert normals in to eye space (It is done by GLSL compiler internally under mat3 conversion.
         3. Convert normals in to eye space.
         4. Calculate source vector by substracting eyeCoordinates from light position.
         5. Calculate diffuse_light, by multiply {ld * kd * "dot product of source vector and notmal vectors"}
         */
        
        glShaderSource(vertextShaderObject, 1, (const GLchar **)&vertexShaderSourceCode, NULL);
        
        //******************* Compile Vertex shader
        glCompileShader(vertextShaderObject);
        
        GLint iInfoLogLength = 0;
        GLint iShaderCompiledStatus = 0;
        char *szInfoLog = NULL;
        glGetShaderiv(vertextShaderObject, GL_COMPILE_STATUS, &iShaderCompiledStatus);
        if (iShaderCompiledStatus == GL_FALSE)
        {
            glGetShaderiv(vertextShaderObject, GL_INFO_LOG_LENGTH, &iInfoLogLength);
            if (iInfoLogLength > 0)
            {
                szInfoLog = (char *)malloc(iInfoLogLength);
                if (szInfoLog != NULL)
                {
                    GLsizei written;
                    glGetShaderInfoLog(vertextShaderObject, iInfoLogLength, &written, szInfoLog);
                    printf("***** Vertex Shader Compilation Log : %s\n", szInfoLog);
                    free(szInfoLog);
                    [self release];
                }
            }
        }
        
        //**************************************** Fragment shader **********************************************
        fragmentShaderObject = glCreateShader(GL_FRAGMENT_SHADER);
        
        const GLchar *fragmentShaderSourceCode =
        "#version 300 es"\
        "\n"\
        "precision highp float;" \
        "precision highp int;" \
        "in vec3 transformed_normals;" \
        "in vec3 light_direction_red;" \
        "in vec3 light_direction_green;" \
        "in vec3 light_direction_blue;" \
        "in vec3 viewer_vector;" \
        "out vec4 FragColor;" \
        "uniform vec3 u_La;" \
        "uniform vec3 u_Ld_red;" \
        "uniform vec3 u_Ld_green;" \
        "uniform vec3 u_Ld_blue;" \
        "uniform vec3 u_Ls;" \
        "uniform vec3 u_Ka;" \
        "uniform vec3 u_Kd;" \
        "uniform vec3 u_Ks;" \
        "uniform float u_material_shininess;" \
        "uniform int u_lighting_enabled;" \
        "void main(void)" \
        "{" \
        "vec3 phong_ads_color;" \
        "if(u_lighting_enabled==1)" \
        "{" \
        "vec3 normalized_transformed_normals=normalize(transformed_normals);" \
        "vec3 normalized_light_direction=normalize(light_direction_red);" \
        "vec3 normalized_viewer_vector=normalize(viewer_vector);" \
        "vec3 ambient = u_La * u_Ka;" \
        "float tn_dot_ld = max(dot(normalized_transformed_normals, normalized_light_direction),0.0);" \
        "vec3 diffuse = u_Ld_red * u_Kd * tn_dot_ld;" \
        "vec3 reflection_vector = reflect(-normalized_light_direction, normalized_transformed_normals);" \
        "vec3 specular = u_Ls * u_Ks * pow(max(dot(reflection_vector, normalized_viewer_vector), 0.0), u_material_shininess);" \
        "phong_ads_color=ambient + diffuse + specular;" \
        
        "normalized_light_direction=normalize(light_direction_blue);" \
        "tn_dot_ld = max(dot(normalized_transformed_normals, normalized_light_direction),0.0);" \
        "diffuse = u_Ld_blue * u_Kd * tn_dot_ld;" \
        "reflection_vector = reflect(-normalized_light_direction, normalized_transformed_normals);" \
        "specular = u_Ls * u_Ks * pow(max(dot(reflection_vector, normalized_viewer_vector), 0.0), u_material_shininess);" \
        "phong_ads_color= phong_ads_color + (ambient + diffuse + specular);" \
        
        "normalized_light_direction=normalize(light_direction_green);" \
        "tn_dot_ld = max(dot(normalized_transformed_normals, normalized_light_direction),0.0);" \
        "diffuse = u_Ld_green * u_Kd * tn_dot_ld;" \
        "reflection_vector = reflect(-normalized_light_direction, normalized_transformed_normals);" \
        "specular = u_Ls * u_Ks * pow(max(dot(reflection_vector, normalized_viewer_vector), 0.0), u_material_shininess);" \
        "phong_ads_color= phong_ads_color + (ambient + diffuse + specular);" \
        
        "}" \
        "else" \
        "{" \
        "phong_ads_color = vec3(1.0, 1.0, 1.0);" \
        "}" \
        "FragColor = vec4(phong_ads_color, 1.0);" \
        "}";


        
        glShaderSource(fragmentShaderObject, 1, (const GLchar **)&fragmentShaderSourceCode, NULL);
        
        //******************* Compile fragment shader
        
        glCompileShader(fragmentShaderObject);
        glGetShaderiv(fragmentShaderObject, GL_COMPILE_STATUS, &iShaderCompiledStatus);
        if (iShaderCompiledStatus == GL_FALSE)
        {
            glGetShaderiv(fragmentShaderObject, GL_INFO_LOG_LENGTH, &iInfoLogLength);
            if (iInfoLogLength > 0)
            {
                szInfoLog = (char *)malloc(iInfoLogLength);
                if (szInfoLog != NULL)
                {
                    GLsizei written;
                    glGetShaderInfoLog(fragmentShaderObject, iInfoLogLength, &written, szInfoLog);
                    printf("***** Fragment Shader Compilation Log : %s\n", szInfoLog);
                    free(szInfoLog);
                    
                }
            }
        }
        
        //**************************************** Shader program attachment **********************************************
        // Code from sir
        
        shaderProgramObject = glCreateProgram();
        
        // attach vertex shader to shader program
        glAttachShader(shaderProgramObject, vertextShaderObject);
        
        // attach fragment shader to shader program
        glAttachShader(shaderProgramObject, fragmentShaderObject);
        
        glBindAttribLocation(shaderProgramObject, VVZ_ATTRIBUTE_VERTEX, "vPosition");
        glBindAttribLocation(shaderProgramObject, VVZ_ATTRIBUTE_NORMAL, "vNormal");


        
        //**************************************** Link Shader program **********************************************
        glLinkProgram(shaderProgramObject);
        GLint iShaderProgramLinkStatus = 0;
        glGetProgramiv(shaderProgramObject, GL_LINK_STATUS, &iShaderProgramLinkStatus);
        if (iShaderProgramLinkStatus == GL_FALSE)
        {
            glGetProgramiv(shaderProgramObject, GL_INFO_LOG_LENGTH, &iInfoLogLength);
            if (iInfoLogLength>0)
            {
                szInfoLog = (char *)malloc(iInfoLogLength);
                if (szInfoLog != NULL)
                {
                    GLsizei written;
                    glGetProgramInfoLog(shaderProgramObject, iInfoLogLength, &written, szInfoLog);
                    printf("Shader Program Link Log : %s\n", szInfoLog);
                    free(szInfoLog);
                    [self release];
                }
            }
        }
        
        //**************************************** END Link Shader program **********************************************
        // get uniform locations
        model_matrix_uniform = glGetUniformLocation(shaderProgramObject, "u_model_matrix");
        view_matrix_uniform = glGetUniformLocation(shaderProgramObject, "u_view_matrix");
        projection_matrix_uniform = glGetUniformLocation(shaderProgramObject, "u_projection_matrix");
        
        
        gLKeyPressedUniform = glGetUniformLocation(shaderProgramObject, "u_lighting_enabled");
        
        // ambient color intensity of light
        La_uniform = glGetUniformLocation(shaderProgramObject, "u_La");
        // specular color intensity of light
        Ls_uniform = glGetUniformLocation(shaderProgramObject, "u_Ls");
        // position of light
        Ld_uniform_red = glGetUniformLocation(shaderProgramObject, "u_Ld_red");
        light_position_uniform_red = glGetUniformLocation(shaderProgramObject, "u_light_position_red");;
        
        
        Ld_uniform_green = glGetUniformLocation(shaderProgramObject, "u_Ld_green");
        light_position_uniform_green = glGetUniformLocation(shaderProgramObject, "u_light_position_green");;
        
        Ld_uniform_blue = glGetUniformLocation(shaderProgramObject, "u_Ld_blue");
        light_position_uniform_blue = glGetUniformLocation(shaderProgramObject, "u_light_position_blue");;

        // ambient reflective color intensity of material
        Ka_uniform = glGetUniformLocation(shaderProgramObject, "u_Ka");
        // diffuse reflective color intensity of material
        Kd_uniform = glGetUniformLocation(shaderProgramObject, "u_Kd");
        // specular reflective color intensity of material
        Ks_uniform = glGetUniformLocation(shaderProgramObject, "u_Ks");
        // shininess of material ( value is conventionally between 1 to 200 )
       
        material_shininess_uniform = glGetUniformLocation(shaderProgramObject, "u_material_shininess");;
        
        // *** vertices, colors, shader attribs, vbo, vao initializations ***
        
        Sphere *sphere = new Sphere();
        sphere->getSphereVertexData(sphere_vertices, sphere_normals, sphere_textures, sphere_elements);
        
        gNumVertices = sphere->getNumberOfSphereVertices();
        gNumElements = sphere->getNumberOfSphereElements();
        
        // vao
        glGenVertexArrays(1, &gVao_sphere);
        glBindVertexArray(gVao_sphere);
        
        // position vbo
        glGenBuffers(1, &gVbo_sphere_position);
        glBindBuffer(GL_ARRAY_BUFFER, gVbo_sphere_position);
        glBufferData(GL_ARRAY_BUFFER, sizeof(sphere_vertices), sphere_vertices, GL_STATIC_DRAW);
        
        glVertexAttribPointer(VVZ_ATTRIBUTE_VERTEX, 3, GL_FLOAT, GL_FALSE, 0, NULL);
        
        glEnableVertexAttribArray(VVZ_ATTRIBUTE_VERTEX);

        glBindBuffer(GL_ARRAY_BUFFER, 0);
        
        //***********************************************
        glGenBuffers(1, &gVbo_sphere_normal);
        glBindBuffer(GL_ARRAY_BUFFER, gVbo_sphere_normal);
        glBufferData(GL_ARRAY_BUFFER, sizeof(sphere_normals), sphere_normals, GL_STATIC_DRAW);
        
        glVertexAttribPointer(VVZ_ATTRIBUTE_NORMAL, 3, GL_FLOAT, GL_FALSE, 0, NULL);
        
        glEnableVertexAttribArray(VVZ_ATTRIBUTE_NORMAL);
        
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        
        // element vbo
        glGenBuffers(1, &gVbo_sphere_element);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gVbo_sphere_element);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(sphere_elements), sphere_elements, GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

        //*************************************************
        
        
        //glShadeModel(GL_SMOOTH);
        
        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_LEQUAL);
        // glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
        //glEnable(GL_CULL_FACE);
        
        glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
        
        gPerspectiveProjectionMatrix  = vmath::mat4::identity();

        
        // GESTURE RECOGNITION
        // Tap gesture code
        UITapGestureRecognizer *singleTapGestureRecognizer=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onSingleTap:)];
        [singleTapGestureRecognizer setNumberOfTapsRequired:1];
        [singleTapGestureRecognizer setNumberOfTouchesRequired:1]; // touch of 1 finger
        [singleTapGestureRecognizer setDelegate:self];
        [self addGestureRecognizer:singleTapGestureRecognizer];
        
        UITapGestureRecognizer *doubleTapGestureRecognizer=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onDoubleTap:)];
        [doubleTapGestureRecognizer setNumberOfTapsRequired:2];
        [doubleTapGestureRecognizer setNumberOfTouchesRequired:1]; // touch of 1 finger
        [doubleTapGestureRecognizer setDelegate:self];
        [self addGestureRecognizer:doubleTapGestureRecognizer];
        
        // this will allow to differentiate between single tap and double tap
        [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
        
        // swipe gesture
        UISwipeGestureRecognizer *swipeGestureRecognizer=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(onSwipe:)];
        [self addGestureRecognizer:swipeGestureRecognizer];
        
        // long-press gesture
        UILongPressGestureRecognizer *longPressGestureRecognizer=[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(onLongPress:)];
        [self addGestureRecognizer:longPressGestureRecognizer];
    }
    return(self);
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

+(Class)layerClass
{
    // code
    return([CAEAGLLayer class]); //return class which indicates we want to do animation
    //core animation embedded Apple GL(opengl es)
    //this method will called by super class, and ultimately it called by Cocoa Touch and ultimately iOS
}

-(void)drawView:(id)sender
{
    [self updateAngleRotateRed];
    [self updateAngleRotateGreen];
    [self updateAngleRotateBlue];
    
    [EAGLContext setCurrentContext:eaglContext];
    
    GLfloat lightAmbient[]= {0.0f,0.0f,0.0f,1.0f};
    GLfloat lightSpecular[] = { 1.0f,1.0f,1.0f,1.0f };
    
    GLfloat lightDiffuseRed[] = { 1.0f,0.0f,0.0f,0.0f };
    GLfloat lightPositionRed[] = { 100.0f,100.0f,100.0f,1.0f };
    
    GLfloat lightDiffuseGreen[] = { 0.0f,1.0f,0.0f,0.0f };
    GLfloat lightPositionGreen[] = { 100.0f,100.0f,100.0f,1.0f };
    
    GLfloat lightDiffuseBlue[] = { 0.0f,0.0f,1.0f,0.0f };
    GLfloat lightPositionBlue[] = { 100.0f,100.0f,100.0f,1.0f };
    
    GLfloat material_ambient[] = { 0.0f,0.0f,0.0f,1.0f };
    GLfloat material_diffuse[] = { 1.0f,1.0f,1.0f,1.0f };
    GLfloat material_specular[] = { 1.0f,1.0f,1.0f,1.0f };
    GLfloat material_shininess = 50.0f;


    
    
    glBindFramebuffer(GL_FRAMEBUFFER,defaultFramebuffer);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
    
    glUseProgram(shaderProgramObject);
    
    if (gbLight == true)
    {
        glUniform1i(gLKeyPressedUniform, 1);
        
        
        
        lightPositionRed[0] = cos(angleRotateRed)*100.0;
        lightPositionRed[1]=0.0;
        lightPositionRed[2]=sin(angleRotateRed)*100.0;
        lightPositionRed[3]=100.0;
        
        lightPositionGreen[0] = 0.0;
        lightPositionGreen[1]=cos(angleRotateGreen)*100.0;
        lightPositionGreen[2]=sin(angleRotateGreen)*100.0;
        lightPositionGreen[3]=100.0 ;
        
        lightPositionBlue[0] = -cos(angleRotateBlue)*100.0;
        lightPositionBlue[1]=0.0;
        lightPositionBlue[2]=sin(angleRotateBlue)*100.0;
        lightPositionBlue[3]=100.0;
        
        
        // setting light's properties
        glUniform3fv(La_uniform, 1, lightAmbient);
        glUniform3fv(Ls_uniform, 1, lightSpecular);
        
        glUniform3fv(Ld_uniform_red, 1, lightDiffuseRed);
        glUniform4fv(light_position_uniform_red, 1, lightPositionRed);
        
        glUniform3fv(Ld_uniform_green, 1, lightDiffuseGreen);
        glUniform4fv(light_position_uniform_green, 1, lightPositionGreen);
        
        glUniform3fv(Ld_uniform_blue, 1, lightDiffuseBlue);
        glUniform4fv(light_position_uniform_blue, 1, lightPositionBlue);
        
        // setting material's properties
        glUniform3fv(Ka_uniform, 1, material_ambient);
        glUniform3fv(Kd_uniform, 1, material_diffuse);
        glUniform3fv(Ks_uniform, 1, material_specular);
        glUniform1f(material_shininess_uniform, material_shininess);
        
        
    }
    else
    {
        glUniform1i(gLKeyPressedUniform, 0);
    }
    
    
    // OpenGL Drawing
    // set all matrices to identity
    vmath::mat4 modelMatrix = vmath::mat4::identity();
    vmath::mat4 viewMatrix = vmath::mat4::identity();
    
    //vmath::mat4 rotationMatrix = vmath::mat4::identity();
    
    // apply z axis translation to go deep into the screen by -5.0,
    // so that triangle with same fullscreen co-ordinates, but due to above translation will look small
    modelMatrix = vmath::translate(0.0f, 0.0f, -2.0f);
    
    
    glUniformMatrix4fv(model_matrix_uniform, 1, GL_FALSE, modelMatrix);
    glUniformMatrix4fv(view_matrix_uniform, 1, GL_FALSE, viewMatrix);
    glUniformMatrix4fv(projection_matrix_uniform, 1, GL_FALSE, gPerspectiveProjectionMatrix);
    
    // *** bind vao ***
    glBindVertexArray(gVao_sphere);
    
    // *** draw, either by glDrawTriangles() or glDrawArrays() or glDrawElements()
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gVbo_sphere_element);
    glDrawElements(GL_TRIANGLES, gNumElements, GL_UNSIGNED_SHORT, 0);
    
    // *** unbind vao ***
    glBindVertexArray(0);
    
    // stop using OpenGL program object
    glUseProgram(0);
    
    glBindRenderbuffer(GL_RENDERBUFFER,colorRenderbuffer);
    [eaglContext presentRenderbuffer:GL_RENDERBUFFER];
}

-(void)layoutSubviews  // equivalent to resize() function
{
    GLint width;
    GLint height;
    
    
    // after resize window, we need to remove frame buffer and create new frame buffer with new Width and height
    glBindRenderbuffer(GL_RENDERBUFFER,colorRenderbuffer);
    [eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER,GL_RENDERBUFFER_WIDTH,&width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER,GL_RENDERBUFFER_HEIGHT,&height);
    
    glGenRenderbuffers(1,&depthRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER,depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER,GL_DEPTH_COMPONENT16,width,height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,GL_DEPTH_ATTACHMENT,GL_RENDERBUFFER,depthRenderbuffer);
    
    
    
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        printf("Failed To Create Complete Framebuffer Object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    
    glViewport(0,0,width,height);
    
    GLfloat fWidth = (GLfloat)width;
    GLfloat fHeight = (GLfloat)height;
    
    gPerspectiveProjectionMatrix  = vmath::perspective(45, fWidth/fHeight, 0.1f, 100.0f);

//    if (width <= height)
//        orthoGraphicProjectionMatrix = vmath::ortho(-100.0f, 100.0f, (-100.0f * (fHeight / fWidth)), (100.0f * (fHeight / fWidth)), -100.0f, 100.0f);
//    else
//        orthoGraphicProjectionMatrix = vmath::ortho((-100.0f * (fWidth / fHeight)), (100.0f * (fWidth / fHeight)), -100.0f, 100.0f, -100.0f, 100.0f);
//
    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
    {
        printf("Failed To Create Complete Framebuffer Object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    [self drawView:nil]; // in webgl, Android,iphone resize does not call paint implicitly so we need to call it explicitly.
}

-(void)startAnimation // uset defined function. Need to declare thid in MyView.h
{
    if (!isAnimating)
    {
        displayLink=[NSClassFromString(@"CADisplayLink")displayLinkWithTarget:self selector:@selector(drawView:)];
        //NSClassFromString is like reflection, get class from literal name
        [displayLink setPreferredFramesPerSecond:animationFrameInterval];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];// register to message/run loop
        //tracking mode, event tracking mode, intrupts mode, and default mode
        isAnimating=YES;
    }
}

-(void)stopAnimation // uset defined function. Need to declare thid in MyView.h
{
    if(isAnimating)
    {
        [displayLink invalidate];// stop the display and take out of run loop
        displayLink=nil;
        
        isAnimating=NO;
    }
}

// to become first responder
-(BOOL)acceptsFirstResponder
{
    // code
    return(YES);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

-(void)onSingleTap:(UITapGestureRecognizer *)gr
{
    
}

-(void)onDoubleTap:(UITapGestureRecognizer *)gr
{
    if(gbLight==true)
        gbLight=false;
    else
        gbLight=true;
}

-(void)onSwipe:(UISwipeGestureRecognizer *)gr
{
    // code
    [self release];
    exit(0);
}

-(void)onLongPress:(UILongPressGestureRecognizer *)gr
{
    
}

-(void) updateAngleRotateRed
{
    if (angleRotateRed==360.0f)
        angleRotateRed=0.0f;
    else
        angleRotateRed=angleRotateRed+0.1f;
}

-(void) updateAngleRotateGreen
{
    if (angleRotateGreen==360.0f)
        angleRotateGreen=0.0f;
    else
        angleRotateGreen=angleRotateGreen+0.1f;
}

-(void) updateAngleRotateBlue
{
    if (angleRotateBlue==360.0f)
        angleRotateBlue=0.0f;
    else
        angleRotateBlue=angleRotateBlue+0.1f;
}

- (void)dealloc
{
    // code
    if(depthRenderbuffer)
    {
        glDeleteRenderbuffers(1,&depthRenderbuffer);
        depthRenderbuffer=0;
    }
    
    if(colorRenderbuffer)
    {
        glDeleteRenderbuffers(1,&colorRenderbuffer);
        colorRenderbuffer=0;
    }
    
    if(defaultFramebuffer)
    {
        glDeleteFramebuffers(1,&defaultFramebuffer);
        defaultFramebuffer=0;
    }
    
    if([EAGLContext currentContext]==eaglContext)
    {
        [EAGLContext setCurrentContext:nil];
    }
    [eaglContext release];
    eaglContext=nil;
    
    [super dealloc];
}

@end
