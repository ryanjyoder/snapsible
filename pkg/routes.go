package pkg

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func WireRoutes(r *gin.Engine, service *Setuper) {

	// Get user value
	r.GET("/user/:name", func(c *gin.Context) {
		user := c.Params.ByName("name")

		c.JSON(http.StatusOK, gin.H{"user": user, "status": "no value"})

	})

	r.POST("/setup", func(c *gin.Context) {
		status, err := service.DoSetup(c)
		if err != nil {
			c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, status)
	})

}
