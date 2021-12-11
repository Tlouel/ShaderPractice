using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ChangeMatWhenHit : MonoBehaviour {
    
    Shader outlineShader;

    void Start() {
        outlineShader = Shader.Find("Unlit/Outline");
    }

   
    void Update() {
        
        if(Input.GetMouseButtonDown(0)){
            RaycastHit hit;
            Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);

            if(Physics.Raycast(ray, out hit, 100.0f)) {
                hit.collider.gameObject.GetComponent<RotativeObject>().rotation.x = 0.2f;
                Transform parent = hit.collider.gameObject.transform.parent;
                
                for(int i = 0; i < parent.childCount; i++) {
                    GameObject childObj = parent.GetChild(i).gameObject;
                    childObj.GetComponent<RotativeObject>().rotation.x = 0;
                    childObj.GetComponent<Renderer>().sharedMaterial.shader = Shader.Find("Standard");
                }

                GameObject gameObj = hit.collider.gameObject;
                Material mat = gameObj.GetComponent<Renderer>().material;
                gameObj.GetComponent<RotativeObject>().rotation.x = 2.2f;
                mat.shader = outlineShader;
                mat.SetFloat("_Outline", 0.1f);
            }
        }
        
    }
}
