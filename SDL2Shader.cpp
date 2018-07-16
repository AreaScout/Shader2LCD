#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <iostream>
#include <ctime>
#include <SOIL/SOIL.h>
#include <string>
#include <sys/time.h>
#include <fcntl.h>
#include <sys/mman.h>

#define GL_GLEXT_PROTOTYPES 1

#include <SDL2/SDL.h>
#include <SDL2/SDL_opengles2.h>
#include <GLES3/gl3.h>
#include <GLES3/gl31.h>
#include <GLES3/gl3ext.h>

std::string _fragmentShader;
std::string _textureName;
timeval     _startTime;

GLuint      _texture0;

GLuint      _vbo_quad;
GLuint      _program;
GLint       _attribute_coord2d;
bool bIsRunning;

uint32_t rmask = 0x00ff0000, gmask = 0x0000ff00, bmask = 0x000000ff, amask = 0xff000000;
uint8_t *fbp = NULL;
uint8_t buffer[320 * 240 * 4] = {0};
SDL_Surface *fbdev_surface = NULL;

typedef GLubyte* (APIENTRY * glGetString_Func)(unsigned int);
glGetString_Func glGetStringAPI = NULL;

char* file_read(const char* filename)
{
	FILE* in = fopen(filename, "rb");
	if (in == NULL) return NULL;
	
	int res_size = BUFSIZ;
	char* res = (char*)malloc(res_size);
	int nb_read_total = 0;
	
	while (!feof(in) && !ferror(in)) {
		if (nb_read_total + BUFSIZ > res_size) {
			if (res_size > 10*1024*1024) break;
			res_size = res_size * 2;
			res = (char*)realloc(res, res_size);
		}
		char* p_res = res + nb_read_total;
		nb_read_total += fread(p_res, 1, BUFSIZ, in);
	}
	
	fclose(in);
	res = (char*)realloc(res, nb_read_total + 1);
	res[nb_read_total] = '\0';
	
	return res;
}

/**
 * Display compilation errors from the OpenGL shader compiler
 */
void print_log(GLuint object)
{
	GLint log_length = 0;
	if (glIsShader(object))
		glGetShaderiv(object, GL_INFO_LOG_LENGTH, &log_length);
	else if (glIsProgram(object))
		glGetProgramiv(object, GL_INFO_LOG_LENGTH, &log_length);
	else {
		fprintf(stderr, "printlog: Not a shader or a program\n");
		return;
	}
	
	char* log = (char*)malloc(log_length);
	
	if (glIsShader(object))
	glGetShaderInfoLog(object, log_length, NULL, log);
	else if (glIsProgram(object))
	glGetProgramInfoLog(object, log_length, NULL, log);
	
	fprintf(stderr, "%s", log);
	free(log);
}

/**
 * Compile the shader from file 'filename', with error handling
 */
GLuint create_shader(const char* filename, GLenum type)
{
	const GLchar* source = file_read(filename);
	if (source == NULL) {
		fprintf(stderr, "Error opening %s: ", filename); perror("");
		return 0;
	}
	GLuint res = glCreateShader(type);
	const GLchar* sources[] = {
		// Define GLSL version
		"#version 100\n"
		,
		// GLES2 precision specifiers
		// Define default float precision for fragment shaders:
		(type == GL_FRAGMENT_SHADER) ?
		"#ifdef GL_FRAGMENT_PRECISION_HIGH\n"
		"precision highp float;           \n"
		"#else                            \n"
		"precision mediump float;         \n"
		"#endif                           \n"
		: ""
		,
		source };
		glShaderSource(res, 3, sources, NULL);
		free((void*)source);
		
		glCompileShader(res);
		GLint compile_ok = GL_FALSE;
		glGetShaderiv(res, GL_COMPILE_STATUS, &compile_ok);
		if (compile_ok == GL_FALSE) {
		fprintf(stderr, "%s:", filename);
		print_log(res);
		glDeleteShader(res);
		return 0;
	}
	
	return res;
}

int init_resources()
{
	GLfloat triangle_vertices[] = {
		-1.0, -1.0,
		 1.0, -1.0,
		-1.0,  1.0,
		 1.0, -1.0,
		 1.0,  1.0,
		-1.0,  1.0
	};

	glGenBuffers(1, &_vbo_quad);
	glBindBuffer(GL_ARRAY_BUFFER, _vbo_quad);
	glBufferData(GL_ARRAY_BUFFER, sizeof(triangle_vertices), triangle_vertices, GL_STATIC_DRAW);
	
	GLint link_ok = GL_FALSE;

	GLuint vs, fs;
	if ((vs = create_shader("shaders/triangle.v.glsl", GL_VERTEX_SHADER))	  == 0) return 0;
	if (_fragmentShader != "") {
		if ((fs = create_shader(_fragmentShader.c_str(), GL_FRAGMENT_SHADER)) == 0) return 0;
	} else if ((fs = create_shader("shaders/triangle.f.glsl", GL_FRAGMENT_SHADER)) == 0) return 0;
	
	_program = glCreateProgram();
	glAttachShader(_program, vs);
	glAttachShader(_program, fs);
	glLinkProgram(_program);
	glGetProgramiv(_program, GL_LINK_STATUS, &link_ok);
	if (!link_ok) {
		fprintf(stderr, "glLinkProgram:");
		print_log(_program);
		return 0;
	}
	
	const char* attribute_name = "coord2d";
	_attribute_coord2d = glGetAttribLocation(_program, attribute_name);
	if (_attribute_coord2d == -1) {
		fprintf(stderr, "Could not bind attribute %s\n", attribute_name);
		return 0;
	}

	return 1;
}

void initializeGL()
{
	init_resources();
	
	// load texture if specified
	if (_textureName != "") {
		_texture0 = SOIL_load_OGL_texture(_textureName.c_str(),	SOIL_LOAD_AUTO,	SOIL_CREATE_NEW_ID,	SOIL_FLAG_MIPMAPS);
	
		/* check for an error during the load process */
		if( 0 == _texture0 ) {
			printf( "SOIL loading error: '%s' '%s'\n", SOIL_last_result(), _textureName.c_str() );
		} else {
			glEnable(GL_TEXTURE_2D);
		}	 
	}
	
	// set the clear colour
	glClearColor(1, 1, 1, 1);
	
	// Start timer
	gettimeofday(&_startTime, NULL);
	bIsRunning = false;
}

float getDeltaTimeS()
{
	timeval currentTime;
	gettimeofday(&currentTime, NULL);

	float deltaTime = (currentTime.tv_sec - _startTime.tv_sec); 
	deltaTime += (currentTime.tv_usec - _startTime.tv_usec) / 1000000.0; // us to s
	return deltaTime;
}

void paintGL()
{
	float r=(float)rand()/(float)RAND_MAX;
	float g=(float)rand()/(float)RAND_MAX;
	float b=(float)rand()/(float)RAND_MAX;

	// set the clear colour
	glClearColor(r, g, b, 1);

	// clear screen
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	// setup fragment shader variables
	glUseProgram(_program);
	GLint unif_resolution, unif_time, unif_tex0, unif_date;

	unif_time = glGetUniformLocation(_program, "time");
	float deltaTimeS = getDeltaTimeS();
	glUniform1f(unif_time, deltaTimeS);  

	unif_resolution = glGetUniformLocation(_program, "resolution");
	glUniform2f(unif_resolution, 320.0f, 240.0f);

	unif_date = glGetUniformLocation(_program, "iDate");
	time_t now = time(NULL);
	tm *ltm = localtime(&now);

	float year = 1900 + ltm->tm_year;
	float month = ltm->tm_mon;
	float day = ltm->tm_mday;
	float sec = (ltm->tm_hour * 60 * 60) + (ltm->tm_min * 60) + ltm->tm_sec;

	glUniform4f(unif_date, year, month, day, sec);

	unif_tex0 = glGetUniformLocation(_program, "tex0");
	if (unif_tex0 != -1) {
		if (_texture0 != 0) {
			glUniform1i(unif_tex0, 0);
			glActiveTexture(GL_TEXTURE0);
			glBindTexture(GL_TEXTURE_2D, _texture0);
		}
	}

	/* Describe our vertices array to OpenGL */
	glBindBuffer(GL_ARRAY_BUFFER, _vbo_quad);
	glVertexAttribPointer(
		_attribute_coord2d, // attribute
		2,				   // number of elements per vertex, here (x,y)
		GL_FLOAT,		   // the type of each element
		GL_FALSE,		   // take our values as-is
		0,				   // no extra data between each position
		0				   // offset of first element
	);
	glEnableVertexAttribArray(_attribute_coord2d);

	/* Push each element in buffer_vertices to the vertex shader */
	glDrawArrays(GL_TRIANGLES, 0, 6);

	glDisableVertexAttribArray(_attribute_coord2d);

	glReadBuffer(GL_COLOR_ATTACHMENT0);
	glPixelStorei(GL_PACK_ALIGNMENT, 4);
	glPixelStorei(GL_PACK_ROW_LENGTH, 0);
	glPixelStorei(GL_PACK_SKIP_ROWS, 0);
	glPixelStorei(GL_PACK_SKIP_PIXELS, 0);
	glReadPixels(0, 0, 320, 240, GL_BGRA_EXT, GL_UNSIGNED_BYTE, &buffer);

    fbdev_surface = SDL_CreateRGBSurfaceFrom(buffer, 320, 240, 32, 1280, rmask, gmask, bmask, amask);
}

SDL_Surface* flip_vertical(SDL_Surface* sfc) {
	SDL_Surface* result = SDL_CreateRGBSurface(sfc->flags, sfc->w, sfc->h, sfc->format->BytesPerPixel * 8, sfc->format->Rmask, sfc->format->Gmask, sfc->format->Bmask, sfc->format->Amask);
	int pitch = sfc->pitch;
	int pxlength = pitch * sfc->h;
	unsigned char *pixels  = (unsigned char*)sfc->pixels + pxlength;
	unsigned char *rpixels = (unsigned char*)result->pixels;
	for(int line = 0; line < sfc->h; ++line) {
		memcpy(rpixels, pixels, pitch);
		pixels -= pitch;
		rpixels += pitch;
	}
	return result;
}

int main(int argc, char *argv[])
{
	bool terminate = false;

	if (argc >= 2)
		_fragmentShader = argv[1];

	if (argc >= 3)
		_textureName = argv[2];
	
	SDL_Init(SDL_INIT_VIDEO);

	SDL_Window* window = NULL;
	SDL_RendererInfo info;
	int drv_index = -1;
	char rendername[256] = {0};
	uint32_t rmask16 = 0x0000f800, gmask16 = 0x000007e0, bmask16 = 0x0000001f, amask16 = 0x00000000;
	int fd;
	int pxlength;
	
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
	SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
	SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 1);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
	SDL_GL_SetAttribute(SDL_GL_ACCELERATED_VISUAL, 1);

	window = SDL_CreateWindow("Shader2LCD", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 320, 240, SDL_WINDOW_OPENGL | SDL_WINDOW_MINIMIZED | SDL_WINDOW_BORDERLESS | SDL_WINDOW_HIDDEN);
	if (!window) {
		fprintf(stderr, "Error: failed to create window: %s\n", SDL_GetError());
		return -1;
	}

	SDL_GLContext ctx = SDL_GL_CreateContext(window);
	SDL_GL_MakeCurrent(window, ctx);

	glGetStringAPI = (glGetString_Func)SDL_GL_GetProcAddress("glGetString");
	
	for (int it = 0; it < SDL_GetNumRenderDrivers(); ++it) {
		SDL_GetRenderDriverInfo(it, &info);

		strcat(rendername, info.name);
		strcat(rendername, " ");
	}

	fprintf(stdout, "Available Renderers: %s\n", rendername);
	fprintf(stdout, "Vendor     : %s\n", glGetStringAPI(GL_VENDOR));
	fprintf(stdout, "Renderer   : %s\n", glGetStringAPI(GL_RENDERER));
	fprintf(stdout, "Version    : %s\n", glGetStringAPI(GL_VERSION));
	fprintf(stdout, "Extensions : %s\n", glGetStringAPI(GL_EXTENSIONS));
	
	initializeGL();
	
	if ((fd = open("/dev/fb1", O_RDWR)) < 0) {
		perror("can't open device");
		abort();
	}	
	
	pxlength = 320 * 240 * 2;
	
	fbp = (uint8_t*)mmap(0, pxlength, PROT_READ | PROT_WRITE, MAP_SHARED, fd, (off_t)0);

	SDL_Surface *surface = SDL_CreateRGBSurface(0, 320, 240, 2 * 8, rmask16, gmask16, bmask16, amask16);
	SDL_Surface *surface_tmp = NULL;
	
	SDL_Event event;
	while (!terminate) {
		while (SDL_PollEvent(&event)) {
			if (event.type == SDL_QUIT) {
				terminate = true;
				break;
			}
		}

		paintGL();

		SDL_BlitSurface((surface_tmp = flip_vertical(fbdev_surface)), NULL, surface, NULL);
		SDL_FreeSurface(surface_tmp);
		unsigned char *pixels = (unsigned char*)surface->pixels;
		for (int it = 0; it < pxlength; it++) {
			fbp[it] = pixels[it];
		}
		usleep(40000); // try to keep roughly 25fps 
		SDL_FreeSurface(fbdev_surface);
	}

	SDL_Quit();

	return 0;
}