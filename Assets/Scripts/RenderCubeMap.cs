using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
[ExecuteInEditMode]
public class RenderCubeMap:MonoBehaviour 
{
    public Cubemap cubemap;
    public  Transform renderFromPosition;

    private void OnEnable()
    {
        OnWizardCreate();
    }

    void OnWizardCreate()
    {
        //create temporary camera for rendering
        GameObject go = new GameObject("CubemapCamera");
        go.AddComponent<Camera>();

        //place it on the object 
        go.transform.position = renderFromPosition.position;

        //render into cubemap
        go.GetComponent<Camera>().RenderToCubemap(cubemap);

        // destroy temporary camera
        DestroyImmediate(go);
    }

}
